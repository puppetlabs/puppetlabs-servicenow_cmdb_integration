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

  def set(path, return_body = nil, query_params = {})
    data = {
      httpRequest: {
        path: normalize_path(path),
      },
      httpResponse: {
        body: return_body,
      },
    }

    data = add_query_params(data, query_params)

    # A new return value for a previously defined mock path will not override the old one.
    # We clear the old path first to ensure we always get the value we expect.
    # However, this will also reset the counter the counter for calls to assert_mock_called
    clear(path)

    reply = response('expectation', data)

    (reply[:code] == '201') ? reply : (raise "#{reply[:message]}: #{reply[:body]}")
  rescue => e
    raise "Setting Mock Failed: #{e}"
  end

  def clear(path)
    data = {
      httpRequest: {
        path: normalize_path(path),
      },
    }

    reply = response('clear', data)
    (reply[:code].to_i == 200) ? reply : (raise "#{reply[:message]}: #{reply[:body]}")
  rescue => e
    raise "Failed to clear mock for path: #{path} \n Error: #{e}"
  end

  def mock_called?(path, query_params = {}, atLeast = nil, atMost = nil)
    data = {
      httpRequest: {
        path: normalize_path(path),
      },
      times: {
        atLeast: 1
      },
    }

    data = add_query_params(data, query_params)

    data[:times][:atLeast] = atLeast unless atLeast.nil?
    data[:times][:atMost] = atMost unless atMost.nil?

    reply = response('verify', data)

    # If the mock has been called the specified number of times the server response
    # is a 202.
    case reply[:code].to_i
    when 202
      true
    when 406
      require 'pry'; binding.pry;
      raise reply[:body]
    else
      raise 'incorrect request format'
    end
  rescue => e
    raise "Failed to assert mock called: #{e}"
  end

  def reset_mock_counter(path)
    data = {
      path: normalize_path(path),
    }
    reply = response('clear?type=LOG', data)
    (reply[:code].to_i == 200) ? reply : (raise "#{reply[:message]}: #{reply[:body]}")
  rescue => e
    raise "Failed to reset expectation counter: #{e}"
  end

  def normalize_path(path)
    path.prepend('/') unless path.start_with?('/')
    path.delete_suffix!('/') if path.end_with?('/')
    path << "\/?" unless path.end_with?('/?')
    path
  end

  def add_query_params(data, query_params)
    parameters = {}
    query_params.each do |param, values|
      parameters[param] = [values].flatten
    end

    data[:httpRequest][:queryStringParameters] = parameters unless parameters.empty?
    data
  end
end
