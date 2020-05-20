require 'yaml'
require 'spec_helper'
require 'openssl'

require_relative '../../../files/servicenow.rb'

describe 'servicenow' do
  let(:api_response) { File.read('./spec/support/files/valid_api_response.json') }
  let(:config) { JSON.parse(File.read('./spec/support/files/default_config.json')) }
  let(:node_data_hash) { JSON.parse(servicenow('blah'))['servicenow'] }

  before(:each) do
    allow(YAML).to receive(:load_file).and_return(config)
    allow(Net::HTTP).to receive(:start).with("#{config['instance']}.service-now.com", 443, use_ssl: true, verify_mode: 0).and_return(api_response)
  end

  context 'node does not exist' do
    let(:api_response) do
      '{"result": []}'
    end

    it 'returns an empty servicenow key' do
      expect(node_data_hash).to be_empty
    end
  end

  context 'node exists' do
    it "returns the node's CMDB record" do
      expected_cmdb_record = JSON.parse(api_response)['result'][0]
      expect(node_data_hash).to eql(expected_cmdb_record)
    end

    context 'CMDB record contains classification fields' do
      let(:environment) { 'blah' }
      let(:classes) do
        {
          'class::foo' => {
            'param1' => 'value1',
            'param2' => 'value2',
          },
          'class::blah' => {
            'param1' => 'value1',
            'param2' => 'value2',
          },
          'class::bar' => {},
        }
      end
      let(:api_response) do
        response = JSON.parse(super())

        cmdb_record = response['result'][0]
        cmdb_record['u_puppet_environment'] = environment

        # Need to name as puppet_classes so that we can still access
        # the 'classes' let variable
        puppet_classes = classes
        puppet_classes = puppet_classes.to_json unless puppet_classes.is_a?(String)
        cmdb_record['u_puppet_classes'] = puppet_classes

        response['result'][0] = cmdb_record

        response.to_json
      end

      it 'munges the u_puppet keys correctly' do
        expect(node_data_hash['puppet_environment']).not_to be_empty
        expect(node_data_hash['puppet_classes']).not_to be_empty
      end

      it 'has a puppet_environment key' do
        expect(node_data_hash['puppet_environment']).to eq(environment)
      end

      it 'has a puppet_classes key' do
        expect(node_data_hash['puppet_classes']).to eq(classes)
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

      context 'invalid environment' do
        let(:environment) { 5 }

        it 'throws an error' do
          expect { node_data_hash }.to raise_error(RuntimeError, %r{u_puppet_environment.*String})
        end
      end

      context 'invalid classes' do
        let(:classes) { 'not_json' }

        it 'throws an error' do
          expect { node_data_hash }.to raise_error(RuntimeError, 'u_puppet_classes must be a json serialization of type Hash[String, Hash[String, Any]]')
        end
      end

      context 'classes is the empty string' do
        let(:classes) { '' }

        it 'sets puppet_classes to an empty hash' do
          expect(node_data_hash['puppet_classes']).to eq({})
        end
      end
    end
  end

  context 'checking correct configuration in ServiceNow object' do
    it 'creates servicenow helper with correct parameters' do
      certname = 'example.puppet.com'
      uri = "https://#{config['instance']}.service-now.com/api/now/table/#{config['table']}?#{config['certname_field']}=#{certname}&sysparm_display_value=true"

      expect(ServiceNowRequest).to receive(:new).with(uri, 'Get', nil, config['user'], config['password'])
      expect { servicenow('example.puppet.com') }.to raise_error(NoMethodError)
    end
  end
end
