#!/opt/puppetlabs/puppet/bin/ruby
# rubocop:disable Style/GuardClause

require 'openssl'
require 'net/http'
require 'yaml'
require 'json'

def parse_classification_fields(cmdb_record, classes_field, environment_field)
  if cmdb_record.key?(environment_field)
    # Validate the environment
    environment = cmdb_record.delete(environment_field)
    unless environment.is_a?(String)
      raise "#{environment_field} must be a String"
    end
    # Set it
    cmdb_record['puppet_environment'] = environment
  end

  if cmdb_record.key?(classes_field)
    # Validate the classes_field
    classes = cmdb_record.delete(classes_field)
    classes = '{}' if classes.empty?
    begin
      classes = JSON.parse(classes)
      raise unless classes.is_a? Hash

      classes.each do |_puppet_class, params|
        raise unless params.is_a? Hash
      end
    rescue
      raise "#{classes_field} must be a json serialization of type Hash[String, Hash[String, Any]]"
    end

    # Create the hiera_data key to store class parameters. This is needed
    # to fetch them from Hiera.
    hiera_data = {}
    classes.each do |puppet_class, vars|
      vars.each do |var_name, value|
        class_and_param_name = "#{puppet_class}::#{var_name}"
        hiera_data[class_and_param_name] = value
      end
    end
    # This key will be used by the classification class to ensure
    # that the Hiera backend's properly setup.
    hiera_data['servicenow_cmdb_integration_data_backend_present'] = true

    # Set the classes and hiera data
    cmdb_record['puppet_classes'] = classes
    cmdb_record['hiera_data'] = hiera_data
  end
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

def servicenow(certname)
  config = YAML.load_file('/etc/puppetlabs/puppet/servicenow.yaml')

  instance          = config['instance']
  username          = config['user']
  password          = config['password']
  table             = config['table']
  certname_field    = config['certname_field']
  classes_field     = config['classes_field']
  environment_field = config['environment_field']

  uri = "https://#{instance}.service-now.com/api/now/table/#{table}?#{certname_field}=#{certname}&sysparm_display_value=true"

  cmdb_request = ServiceNowRequest.new(uri, 'Get', nil, username, password)

  cmdb_record = JSON.parse(cmdb_request.response)['result'][0] || {}
  parse_classification_fields(cmdb_record, classes_field, environment_field)

  response = {
    servicenow: cmdb_record,
  }.to_json

  response
end

if $PROGRAM_NAME == __FILE__
  puts servicenow(ARGV[0])
end
