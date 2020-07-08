# rubocop:disable RSpec/HookArgument

require 'json'
require 'securerandom'
require 'sinatra'
require 'base64'

# Our mock ServiceNow instance is a Sinatra server that mimics
# the relevant ServiceNow API endpoints used by the tests
class MockServiceNowInstance < Sinatra::Base
  set :bind, '0.0.0.0'
  set :port, 1080

  # Initialize the tables
  set :tables,
      'cmdb_ci' => {},
      'cmdb_ci_acc' => {}

  # Configure https
  set :server_settings,
      SSLEnable: true,
      SSLCertName: [['CN', 'Sinatra']]

  before do
    content_type 'application/json'

    auth_header = env['HTTP_AUTHORIZATION'] || ''
    if auth_header.start_with?('Basic')
      username_pass = Base64.decode64(auth_header.gsub('Basic ', ''))
      unless username_pass == 'mock_user:mock_password'
        halt 401, to_error_response("Authorization Failed. Username/Pass incorrect.\nExpected: mock_user:mock_password\nGot: #{username_pass}")
      end
    elsif auth_header.start_with?('Bearer')
      unless auth_header == 'Bearer mock_token'
        halt 401, to_error_response("Authorization Failed. OAuth Token incorrect\nExpected: mock_token\nGot: #{auth_header.gsub('Bearer ', '')}")
      end
    else
      halt 401, to_error_response('No authorization received. Please use username: mock_user password: mock_password, or OAuthToken: mock_token.')
    end
  end

  post '/api/now/table/:table_name' do |table_name|
    validate_table(table_name)

    fields = request.body.read
    begin
      fields = JSON.parse(fields)
    rescue
      halt 400, to_error_response("fields must be a hash of <field> => <value>, got #{fields}")
    end

    # Iterate over the fields and check if any of their values is a JSON object.
    # If yes, assume this is a Name-Value pair field so munge it to how it's actually
    # stored in ServiceNow (stringified JSON where each pair's value is a JSON string
    # [if the value's a Hash/Array]). This simulates the actual API.
    fields.each do |field, value|
      next unless value.is_a?(Hash)

      pairs = value
      pairs.each do |key, val|
        if val.is_a?(Hash) || val.is_a?(Array)
          val = val.to_json
        end
        pairs[key] = val
      end

      fields[field] = pairs.to_json
    end

    fields['sys_id'] = SecureRandom.uuid.delete('-')
    table(table_name)[fields['sys_id']] = fields
    to_response(fields)
  end

  get '/api/now/table/:table_name' do |table_name|
    validate_table(table_name)

    # Get a hash of all the queried fields. Note that this
    # is a simplification of ServiceNow's "query table" API.
    params.delete('table_name')
    query_hash = params.reject do |key, _|
      key.start_with?('sysparm')
    end

    # Select all records 'record' where query_hash is a subhash of 'record'
    satisfying_records = table(table_name).values.select do |record|
      (query_hash.to_a - record.to_a).empty?
    end
    to_response(satisfying_records)
  end

  get '/api/now/table/:table_name/:sys_id' do |table_name, sys_id|
    validate_table(table_name)
    validate_record(table_name, sys_id)
    to_response(table(table_name)[sys_id])
  end

  delete '/api/now/table/:table_name/:sys_id' do |table_name, sys_id|
    validate_table(table_name)
    validate_record(table_name, sys_id)
    table(table_name).delete(sys_id)
    nil
  end

  helpers do
    def tables
      settings.tables
    end

    def table(table_name)
      tables[table_name] ||= {}
    end

    def to_response(result)
      { 'result' => result }.to_json
    end

    def to_error_response(message)
      {
        'error' => {
          'detail' => nil,
          'message' => message,
        },
        'status' => 'failure',
      }.to_json
    end

    def validate_table(table_name)
      halt 400, to_error_response("Invalid table #{table_name}") unless tables.include?(table_name)
    end

    def validate_record(table_name, sys_id)
      halt 400, to_error_response("Invalid record #{sys_id}") unless table(table_name)[sys_id]
    end
  end
end

MockServiceNowInstance.run!
