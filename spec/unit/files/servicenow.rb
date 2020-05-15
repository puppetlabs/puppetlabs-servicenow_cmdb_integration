require 'yaml'
require 'spec_helper'
require 'openssl'
require 'support/servicenow_spec_helpers'

require_relative '../../../files/servicenow.rb'

describe 'servicenow' do
  let(:valid_api_response) { File.read('./spec/support/files/valid_api_response.json') }
  let(:config) { JSON.parse(File.read('./spec/support/files/default_config.json')) }
  let(:certname) { 'example.puppet.com' }
  let(:uri) { "https://#{config['instance']}.service-now.com/api/now/table/#{config['table']}?#{config['certname_field']}=#{certname}&sysparm_display_value=true" }
  let(:node_data_hash) { get_node_data_hash }

  before(:each) do
    # Rubocop doesn't like mocks in before blocks, so we have to hide it in a helper.
    mock_config_yaml
  end

  context 'with valid json response' do
    before(:each) do
      mock_http_with(valid_api_response)
    end

    it 'returns "servicenow" as the top level node' do
      hash = JSON.parse(servicenow('foo'))
      expect(hash['servicenow']).not_to be_nil
    end

    it 'munges the u_puppet keys correctly' do
      expect(node_data_hash['puppet_environment']).not_to be_empty
      expect(node_data_hash['puppet_classes']).not_to be_empty
    end

    it 'has a puppet_environment key' do
      expect(node_data_hash['puppet_environment']).to eq('blah')
    end

    it 'has a puppet_classes key' do
      expect(node_data_hash['puppet_classes']).not_to be_nil
    end

    it 'has a hiera_data key' do
      expect(node_data_hash['hiera_data']).not_to be_nil
    end

    it 'has the correct classes params and values' do
      expect(node_data_hash['hiera_data']['class::foo::param1']).to eq('value1')
      expect(node_data_hash['hiera_data']['class::foo::param2']).to eq('value2')
      expect(node_data_hash['hiera_data']['class::blah::param1']).to eq('value1')
      expect(node_data_hash['hiera_data']['class::blah::param2']).to eq('value2')
    end

    it 'adds the data_backend_present key' do
      expect(node_data_hash['hiera_data']['servicenow_integration_data_backend_present']).to be true
    end
  end

  context 'node does not exist' do
    before(:each) do
      mock_http_with('{"result": []}')
    end

    it 'returns an empty servicenow key' do
      expect(node_data_hash).to be_empty
    end
  end

  context 'invalid classes json' do
    before(:each) do
      response = invalidate_classes_json(valid_api_response)
      mock_http_with(response)
    end

    it 'throws an error if the classes field is not valid json' do
      expect { node_data_hash }.to raise_error(RuntimeError, 'classes must be a json serialization of type Hash[String, Hash[String, Any]]')
    end
  end

  context 'with json missing u_puppet keys' do
    before(:each) do
      response = remove_key_from_json_response(valid_api_response, 'u_puppet_classes')
      response = remove_key_from_json_response(response, 'u_puppet_environment')
      mock_http_with(response)
    end

    it 'specifies both missing keys in the error message' do
      expect { node_data_hash }.to raise_error(RuntimeError, 'required field(s) missing: u_puppet_classes,u_puppet_environment')
    end
  end

  context 'checking correct configuration in ServiceNow object' do
    it 'creates servicenow helper with correct parameters' do
      expect(ServiceNowRequest).to receive(:new).with(uri, 'Get', nil, config['user'], config['password'])
      expect { servicenow('example.puppet.com') }.to raise_error(NoMethodError)
    end
  end
end
