#!/opt/puppetlabs/puppet/bin/ruby
# rubocop:disable Style/GuardClause

# managed by Puppet

require 'openssl'
require 'net/http'
require 'yaml'
require 'json'
require 'erb'

# hiera-eyaml requires. Note that newer versions of puppet-agent
# ship with the hiera-eyaml gem so these should work.
require 'hiera/backend/eyaml/options'
require 'hiera/backend/eyaml/parser/parser'
require 'hiera/backend/eyaml/subcommand'

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

      classes.each do |puppet_class, params|
        case params
        when Hash
          # puppet_classes was a String field type so we've
          # already parsed the params hash
          next
        when String
          # puppet_classes was a Name-Value pairs field type
          # so we'll need to parse the params hash and
          # handle the possibility of an empty value for params
          params = '{}' if params.empty?
          raise unless JSON.parse(params).is_a? Hash
          # If we make it here, the params field was parsed and
          # we save the hash back into the classes var
          classes[puppet_class] = JSON.parse(params)
        else
          # puppet_classes is an invalid field type
          raise
        end
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
  attr_reader :uri

  def initialize(uri, http_verb, body, user, password, oauth_token, options = {})
    unless oauth_token || (user && password)
      raise ArgumentError, 'user/password or oauth_token must be specified'
    end
    @uri = URI.parse(uri)
    @http_verb = http_verb.capitalize
    @body = body.to_json unless body.nil?
    @user = user
    @password = password
    @oauth_token = oauth_token

    @options = options
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
      if @oauth_token
        request['Authorization'] = "Bearer #{@oauth_token}"
      else
        request.basic_auth(@user, @password)
      end
      http.request(request)
    end
  end
end

def servicenow(certname, config_file = nil)
  config_path = config_file.nil? ? '/etc/puppetlabs/puppet/servicenow_cmdb.yaml' : config_file
  servicenow_config = YAML.load_file(config_path)

  instance          = servicenow_config['instance']
  username          = servicenow_config['user']
  password          = servicenow_config['password']
  oauth_token       = servicenow_config['oauth_token']
  table             = servicenow_config['table']
  certname_field    = servicenow_config['certname_field']
  classes_field     = servicenow_config['classes_field']
  environment_field = servicenow_config['environment_field']
  debug             = servicenow_config['debug']

  # Since we also support hiera-eyaml encrypted passwords, we'll want to decrypt
  # the password before passing it into the request. In order to do that, we first
  # check if hiera-eyaml's configured on the node. If yes, then we run the password
  # through hiera-eyaml's parser. The parser will decrypt the password if it is
  # encrypted; otherwise, it will leave it as-is so that plain-text passwords are
  # unaffected.
  hiera_eyaml_config = nil
  begin
    # Note: If hiera-eyaml config doesn't exist, then load_config_file returns
    # the hash {:options => {}, :sources => []}
    hiera_eyaml_config = Hiera::Backend::Eyaml::Subcommand.load_config_file
  rescue StandardError => e
    raise "error reading the hiera-eyaml config: #{e}"
  end
  unless hiera_eyaml_config[:sources].empty?
    # hiera_eyaml config exists so run the password through the parser. Note that
    # we chomp the password to support syntax like:
    #
    #   password: >
    #       ENC[Y22exl+OvjDe+drmik2XEeD3VQtl1uZJXFFF2NnrMXDWx0csyqLB/2NOWefv
    #       NBTZfOlPvMlAesyr4bUY4I5XeVbVk38XKxeriH69EFAD4CahIZlC8lkE/uDh
    #       ...
    #
    # where the '>' will add a trailing newline to the encrypted password.
    #
    # Note that ServiceNow passwords can't contain a newline so chomping's still OK
    # for plain-text passwords.
    Hiera::Backend::Eyaml::Options.set(hiera_eyaml_config[:options])
    parser = Hiera::Backend::Eyaml::Parser::ParserFactory.hiera_backend_parser
    if password
      password_tokens = parser.parse(password.chomp)
      password = password_tokens.map(&:to_plain_text).join
    end

    if oauth_token
      oauth_token_tokens = parser.parse(oauth_token.chomp)
      oauth_token = oauth_token_tokens.map(&:to_plain_text).join
    end
  end

  uri = "https://#{instance}/api/now/table/#{table}?#{certname_field}=#{certname}&sysparm_display_value=true"

  if servicenow_config.key?('snow_uri_erb')
    snow_uri_erb_default = 'https://<%=instance%>/api/now/table/<%=table%>?#<%=certname_field%>=<%=certname%>&sysparm_display_value=true'
    begin
      template = ERB.new(servicenow_config['snow_uri_erb'])
      uri = template.result(binding)
    rescue
      template = ERB.new(snow_uri_erb_default)
      uri = template.result(binding)
    end
  end

  if debug.nil? || debug.empty?
    cmdb_request = ServiceNowRequest.new(uri, 'Get', nil, username, password, oauth_token, { 'certname' => certname }.merge(servicenow_config))
    response = cmdb_request.response
    status = response.code.to_i
    body = response.body
    if status >= 400
      raise "failed to retrieve the CMDB record from #{cmdb_request.uri} (status: #{status}): #{body}"
    end

    cmdb_record = JSON.parse(body)['result'][0] || {}
  else
    cmdb_record = {}
    servicenow_config['password'] = '==PASSWORD==REDACTED==' unless servicenow_config['password'].nil? || servicenow_config['password'].empty?
    servicenow_config['oauth_token'] = '==PASSWORD==REDACTED==' unless servicenow_config['oauth_token'].nil? || servicenow_config['oauth_token'].empty?
    cmdb_record['servicenow_config'] = servicenow_config
    cmdb_record['servicenow_config']['uri'] = uri
  end
  parse_classification_fields(cmdb_record, classes_field, environment_field)

  response = {
    servicenow: cmdb_record,
  }.to_json

  response
end

if $PROGRAM_NAME == __FILE__
  puts servicenow(ARGV[0])
end
