#!/opt/puppetlabs/puppet/bin/ruby

require 'openssl'
require 'net/http'
require 'yaml'
require 'json'

def munge_response(hash, classes_field, environment_field)
  validate_response(hash, classes_field, environment_field) unless ARGV[1] == 'SKIP_VALIDATION'
  hash['puppet_classes'] = hash.delete(classes_field)
  hash['puppet_environment'] = hash.delete(environment_field)

  hash = create_hiera_data_key(hash)

  hash
end

def validate_response(response_hash, classes_field, environment_field)
  missing_fields = []

  [classes_field, environment_field].each do |key|
    missing_fields << key unless response_hash[key]
  end

  raise "required field(s) missing: #{missing_fields.join(',')}" unless missing_fields.count.zero?

  raise "#{environment_field} is not a string" unless response_hash[environment_field].is_a? String

  begin
    classes_hash = JSON.parse(response_hash['u_puppet_classes'])
    raise unless classes_hash.is_a? Hash

    classes_hash.each do |_puppet_class, params|
      raise unless params.is_a? Hash
    end
  rescue
    raise 'classes must be a json serialization of type Hash[String, Hash[String, Any]]'
  end
end

def create_hiera_data_key(hash)
  hiera_data = {}
  classes = JSON.parse(hash['puppet_classes'])

  classes.each do |puppet_class, vars|
    vars.each do |var_name, value|
      class_and_param_name = "#{puppet_class}::#{var_name}"
      hiera_data[class_and_param_name] = value
    end
  end
  # This key will be used by the classification class to ensure
  # that the Hiera backend's properly setup.
  hiera_data['servicenow_integration_data_backend_present'] = true

  hash['hiera_data'] = hiera_data
  hash
end

# Abstract away the API calls.
class ServiceNowRequest
  def initialize(uri, http_verb, body, user, password)
    @uri = URI.parse(uri)
    @http_verb = http_verb.capitalize
    @body = body.to_json unless body.nil?
    @user = user
    @password = password
  end

  def response
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

def get_servicenow_node_data(certname)
  config = YAML.load_file('/etc/puppetlabs/puppet/servicenow.yaml')

  instance          = config['instance']
  username          = config['user']
  password          = config['password']
  table             = config['table']
  certname_field    = config['certname_field']
  classes_field     = config['classes_field']
  environment_field = config['environment_field']

  uri = "https://#{instance}.service-now.com/api/now/table/#{table}?#{certname_field}=#{certname}&sysparm_display_value=true"

  servicenow = ServiceNowRequest.new(uri, 'Get', nil, username, password)

  hash = JSON.parse(servicenow.response)['result'][0] || {}

  unless hash.empty?
    hash = munge_response(hash, classes_field, environment_field)
  end

  response = {
    servicenow: hash,
  }.to_json

  response
end

if $PROGRAM_NAME == __FILE__
  puts get_servicenow_node_data(ARGV[0])
end
