#!/opt/puppetlabs/puppet/bin/ruby

require 'openssl'
require 'net/http'
require 'yaml'
require 'json'

# Abstract away the API calls.
class ServiceNowRequest
  def initialize(uri, http_verb, body, user, password)
    @uri = URI.parse(uri)
    @http_verb = http_verb.capitalize
    @body = body.to_json unless body.nil?
    @user = user
    @password = password
  end

  def print_response
    Net::HTTP.start(@uri.host,
                    @uri.port,
                    use_ssl: @uri.scheme == 'https',
                    verify_mode: OpenSSL::SSL::VERIFY_NONE) do |http|
      header = { 'Content-Type' => 'application/json' }
      # Interpolate the HTTP verb and constantize to a class name.
      request_class_string = "Net::HTTP::#{@http_verb}"
      request_class = Object.const_get(request_class_string)
      # Add uri, fields and authentication to request
      request = request_class.new("#{@uri.path}?#{@uri.query}", header)
      request.body = @body
      request.basic_auth(@user, @password)
      # Make request to ServiceNow
      response = http.request(request)
      # Parse and print response
      response.body
    end
  rescue => e
    raise e
  end
end

if $PROGRAM_NAME == __FILE__
  config = YAML.load_file('/etc/puppetlabs/puppet/servicenow.yaml')

  snowinstance    = config['snowinstance']
  username        = config['user']
  password        = config['password']
  table           = config['table']
  matching_column = config['matching_column']
  certname        = ARGV[0]

  uri = "https://#{snowinstance}.service-now.com/api/now/table/#{table}?#{matching_column}=#{certname}&sysparm_display_value=true"

  request = ServiceNowRequest.new(uri, 'Get', nil, username, password)

  response = {
    servicenow: JSON.parse(request.print_response)['result'][0]
  }.to_json

  puts response

end
