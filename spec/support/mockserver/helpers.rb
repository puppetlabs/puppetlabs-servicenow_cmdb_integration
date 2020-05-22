#!/opt/puppetlabs/puppet/bin/ruby
# rubocop:disable Style/GuardClause

require 'net/http'
require 'json'


class Mockserver
  def initialize(host)
    @base_uri = URI.parse("http://#{host}/mockserver")
  end

  def response(endpoint, body, http_verb = 'Put')
    Net::HTTP.start(@base_uri.host,
                    @base_uri.port,
                    use_ssl: false) do |http|
      request_class = Object.const_get("Net::HTTP::#{http_verb}")
      request       = request_class.new("#{@base_uri.path}/#{endpoint}")
      request.body  = body.to_json unless body.nil?
      response      = http.request(request)
      {
        code:    response.code,
        message: response.message,
        body:    response.body,
      }
    end
  rescue => e
    raise e
  end

  def set(path, return_body = nil, queryStringParameters = nil)
    data = {
      httpRequest: {
        path: normalize_path(path)
      },
      httpResponse: {
        body: return_body
      }
    }

    data = addQueryParams(data, queryStringParameters) unless queryStringParameters.nil?

    require 'pry'; binding.pry;

    # A new return value for a previously defined mock path will not override the old one.
    # We clear the old path first to ensure we always get the value we expect.
    # However, this will also reset the counter the counter for calls to assert_mock_called
    clear(path, queryStringParameters)

    reply = response('expectation', data)

    reply[:code] == '201' ? reply : (raise "#{reply[:message]}: #{reply[:body]}")
  rescue => e
    raise "Setting Mock Failed: #{e}"
  end

  def clear(path, queryStringParameters = nil)
    data = {
      httpRequest: {
        path: normalize_path(path)
      }
    }
    data = addQueryParams(data, queryStringParameters) unless queryStringParameters.nil?
    reply = response('clear', data)
    reply[:code].to_i == 200 ? reply : (raise "#{reply[:message]}: #{reply[:body]}")
  rescue => e
    raise "Failed to clear mock for path: #{path} \n Error: #{e}"
  end

  def assert_mock_called(path, queryStringParameters: nil, atLeast: nil, atMost: nil)
    data = {
      httpRequest: {
        path: normalize_path(path)
      }
    }

    data = addQueryParams(data, queryStringParameters) unless queryStringParameters.nil?

    unless atLeast.nil? && atMost.nil?
      data[:times] = {}
      data[:times][:atLeast] = atLeast unless atLeast.nil?
      data[:times][:atMost] = atMost unless atMost.nil?
    end
    reply = response('verify', data)

    # If the mock has been called the specified number of times the server response
    # is a 202.
    case reply[:code].to_i
    when 202
      true
    when 406
      false
    else
      raise 'incorrect request format'
    end
  rescue => e
    raise "Failed to assert mock called: #{e}"
  end

  def reset_mock_counter(path, queryStringParameters = nil)
    data = {
      path: normalize_path(path)
    }
    data = addQueryParams(data, queryStringParameters) unless queryStringParameters.nil?
    reply = response('clear?type=LOG', data)
    reply[:code].to_i == 200 ? reply : (raise "#{reply[:message]}: #{reply[:body]}")
  rescue => e
    raise "Failed to reset expectation counter: #{e}"
  end

  def normalize_path(path)
    count = path.length - 2
    path.prepend('/') unless path.start_with?('/')
    path.delete_suffix!('/') if path.end_with?('/')
    path << "\/?" unless path.end_with?('/?')
    path
  end

  def addQueryParams(data, queryStringParameters)
    parameters = {}
    queryStringParameters.each do |param,values|
      parameters[param] = [values].flatten
    end

    data[:httpRequest][:queryStringParameters] = parameters
    data
  end
end