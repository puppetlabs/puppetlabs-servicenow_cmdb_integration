# rubocop:disable RSpec/HookArgument

require 'json'
require 'securerandom'
require 'sinatra'

# Our mock ServiceNow instance is a Sinatra server that mimics
# the relevant ServiceNow API endpoints used by the tests
class MockServiceNowInstance < Sinatra::Base
  set :bind, '0.0.0.0'
  set :port, 1080

  # Initialize the CMDB table
  set :cmdb_table, {}

  # Configure https
  set :server_settings,
      SSLEnable: true,
      SSLCertName: [['CN', 'Sinatra']]

  # Handles authorization
  use Rack::Auth::Basic do |user, password|
    user == 'mock_user' && password == 'mock_password'
  end

  before do
    content_type 'application/json'
  end

  post '/api/now/table/:table_name' do |table_name|
    validate_table(table_name)

    fields = request.body.read
    begin
      fields = JSON.parse(fields)
    rescue
      halt 400, to_error_response("fields must be a hash of <field> => <value>, got #{fields}")
    end

    fields['sys_id'] = SecureRandom.uuid.delete('-')
    cmdb_table[fields['sys_id']] = fields
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
    satisfying_records = cmdb_table.values.select do |record|
      (query_hash.to_a - record.to_a).empty?
    end
    to_response(satisfying_records)
  end

  get '/api/now/table/:table_name/:sys_id' do |table_name, sys_id|
    validate_table(table_name)
    validate_record(sys_id)
    to_response(cmdb_table[sys_id])
  end

  delete '/api/now/table/:table_name/:sys_id' do |table_name, sys_id|
    validate_table(table_name)
    validate_record(sys_id)
    cmdb_table.delete(sys_id)
    nil
  end

  helpers do
    def cmdb_table
      settings.cmdb_table
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
      halt 400, to_error_response("Invalid table #{table_name}") unless table_name == 'cmdb_ci'
    end

    def validate_record(sys_id)
      halt 400, to_error_response("Invalid record #{sys_id}") unless cmdb_table[sys_id]
    end
  end
end

MockServiceNowInstance.run!
