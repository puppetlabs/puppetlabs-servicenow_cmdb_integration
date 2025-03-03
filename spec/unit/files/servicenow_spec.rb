# rubocop:disable Metrics/LineLength

require 'yaml'
require 'spec_helper'
require 'openssl'
require 'hashdiff'

require_relative '../../../files/servicenow.rb'

describe 'servicenow' do
  let(:cmdb_api_response_status) { 200 }
  let(:cmdb_api_response_body) { File.read('./spec/support/files/valid_cmdb_api_response.json') }
  let(:config) { YAML.load_file('./spec/support/files/default_config.yaml') }
  let(:node_data_hash) { JSON.parse(servicenow('blah'))['servicenow'] }
  let(:expected_response_json) { File.read('./spec/support/files/servicenow_rb_response.json') }

  before(:each) do
    allow(YAML).to receive(:load_file).with(%r{servicenow_cmdb\.yaml}).and_return(config)

    response_obj = instance_double('Net::HTTP response obj')
    allow(response_obj).to receive(:code).and_return(cmdb_api_response_status.to_s)
    allow(response_obj).to receive(:body).and_return(cmdb_api_response_body)
    allow(Net::HTTP).to receive(:start).with(config['instance'], 443, use_ssl: true, verify_mode: 0).and_return(response_obj)
  end

  context 'without at least one valid method of authentication' do
    it 'will fail' do
      # default values are set to nil in the ServiceNowRequest class.
      expect { ServiceNowRequest.new(nil, nil, nil, nil, nil, nil, anything) }.to raise_error(ArgumentError, 'user/password or oauth_token must be specified')
      expect { ServiceNowRequest.new(nil, nil, nil, 'user', nil, nil, anything) }.to raise_error(ArgumentError, 'user/password or oauth_token must be specified')
      expect { ServiceNowRequest.new(nil, nil, nil, nil, 'password', nil, anything) }.to raise_error(ArgumentError, 'user/password or oauth_token must be specified')
    end
  end

  context 'ServiceNow API returns an error response' do
    let(:cmdb_api_response_status) { 400 }
    let(:cmdb_api_response_body) { 'failed_because' }

    it 'will fail' do
      expect { node_data_hash }.to raise_error(RuntimeError, %r{/now/table.*400.*failed_because})
    end
  end

  context 'node does not exist' do
    let(:cmdb_api_response_body) do
      '{"result": []}'
    end

    it 'returns an empty servicenow key' do
      expect(node_data_hash).to be_empty
    end
  end

  context 'node exists' do
    it "returns the node's parsed CMDB record" do
      expected_cmdb_record = JSON.parse(cmdb_api_response_body)['result'][0]
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
        }.to_json
      end
      let(:cmdb_api_response_body) do
        response = JSON.parse(super())

        cmdb_record = response['result'][0]
        cmdb_record['u_puppet_environment'] = environment
        cmdb_record['u_puppet_classes'] = classes

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
        expect(node_data_hash['puppet_classes']).to eq(JSON.parse(classes))
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
        expect(node_data_hash['hiera_data']['servicenow_cmdb_integration_data_backend_present']).to be true
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

      context 'classes is a Name-Value pair field type' do
        let(:classes_hash) do
          {
            'class::foo' => {
              'param1' => 'value1',
              'param2' => 'value2',
            },
            'class::bar' => {},
          }
        end
        # classes is the raw value of the 'u_puppet_classes' field
        let(:classes) do
          {
            'class::foo' => {
              'param1' => 'value1',
              'param2' => 'value2',
            }.to_json,
            # This also tests that '' is parsed as {}
            'class::bar' => '',
          }.to_json
        end

        it 'still correctly parses the classes' do
          expect(node_data_hash['puppet_classes']).to eq(classes_hash)
        end

        context 'with an invalid value' do
          let(:classes) do
            {
              'class::foo' => {}.to_json,
              'class::bar' => 'not_a_params_hash',
            }.to_json
          end

          it 'throws an error' do
            expect { node_data_hash }.to raise_error(RuntimeError, Regexp.new(Regexp.escape('Hash[String, Any]]')))
          end
        end
      end
    end
  end

  context 'checking correct configuration in ServiceNow object' do
    it 'creates servicenow helper with correct parameters' do
      certname = 'example.puppet.com'
      uri = "https://#{config['instance']}/api/now/table/#{config['table']}?#{config['certname_field']}=#{certname}&sysparm_display_value=true"

      expect(ServiceNowRequest).to receive(:new).with(uri, 'Get', nil, 'admin', 'password', 'oauth_token', anything)
      expect { servicenow('example.puppet.com') }.to raise_error(NoMethodError)
    end
  end

  context 'loading ServiceNow config with custom snow_uri_erb with protocol http URL and check with DEBUG' do
    let(:config) do
      default_config = super()
      default_config['snow_uri_erb'] = 'http://<%=instance%>/<%=table%><%=certname_field%><%=certname%>'
      default_config['debug'] = 'YES'

      default_config['instance'] = 'INSTANCEISUSEDWITH'
      default_config['table'] = 'TABLEWHICHISNOTSPECIFIC'
      default_config['certname_field'] = 'CERTNAMEIS/'

      default_config
    end

    it 'will load with use_ssl:false for uri following format as specified by snow_uri_erb' do
      response_obj_http = instance_double('Net::HTTP response obj')
      allow(response_obj_http).to receive(:code).and_return(cmdb_api_response_status.to_s)
      allow(response_obj_http).to receive(:body).and_return(cmdb_api_response_body)

      allow(Net::HTTP).to receive(:start).with(config['instance'], 80, use_ssl: false, verify_mode: 0).and_return(response_obj_http)
      # allow(Net::HTTP).to receive(:start).with(config['instance'], 80, anything, anything, use_ssl: false, verify_mode: 0).and_return(response_obj_http)

      expect(JSON.parse(servicenow('example'))['servicenow']['servicenow_config']['uri']).to eq('http://INSTANCEISUSEDWITH/TABLEWHICHISNOTSPECIFICCERTNAMEIS/example')
    end
  end

  context 'loading ServiceNow config with custom snow_uri_erb with protocol http' do
    let(:config) do
      default_config = super()
      default_config['snow_uri_erb'] = 'http://<%=instance%>/api/now/table/<%=table%>?#<%=certname_field%>=<%=certname%>&sysparm_display_value=true'
      default_config['debug'] = ''
      default_config
    end
    let(:cmdb_api_response_body_http) do
      d = JSON.parse(cmdb_api_response_body)
      d['result'][0]['protocol'] = 'http protocol'
      data = JSON.generate(d)
      data
    end

    it 'will load with use_ssl:false for http protocol' do
      response_obj_http = instance_double('Net::HTTP response obj')
      allow(response_obj_http).to receive(:code).and_return(cmdb_api_response_status.to_s)
      allow(response_obj_http).to receive(:body).and_return(cmdb_api_response_body_http)

      allow(Net::HTTP).to receive(:start).with(config['instance'], 80, use_ssl: false, verify_mode: 0).and_return(response_obj_http)
      allow(Net::HTTP).to receive(:start).with(config['instance'], 80, anything, anything, use_ssl: false, verify_mode: 0).and_return(response_obj_http)

      expect(JSON.parse(servicenow('example'))['servicenow']['protocol']).to eq('http protocol')
    end
  end

  context 'loading ServiceNow config' do
    shared_context 'setup hiera-eyaml' do
      before(:each) do
        hiera_eyaml_config = {
          pkcs7_private_key: File.absolute_path('./spec/support/common/hiera-eyaml/private_key.pkcs7.pem'),
          pkcs7_public_key: File.absolute_path('./spec/support/common/hiera-eyaml/public_key.pkcs7.pem'),
        }
        # These are what hiera-eyaml's load_config_file method delegates to so we mock them to also
        # test that we're calling the right "load hiera-eyaml config" method
        allow(File).to receive(:file?).and_call_original
        allow(File).to receive(:file?).with('/etc/eyaml/config.yaml').and_return(true)
        allow(YAML).to receive(:load_file).with('/etc/eyaml/config.yaml').and_return(hiera_eyaml_config)
      end
    end

    it 'reads the config from /etc/puppetlabs/puppet/servicenow_cmdb.yaml' do
      expect(YAML).to receive(:load_file).with('/etc/puppetlabs/puppet/servicenow_cmdb.yaml').and_return(config)
      servicenow('example.puppet.com')
    end

    context 'with hiera-eyaml encrypted password' do
      let(:encrypted_password) do
        # This will be set by the tests
        nil
      end
      let(:config) do
        default_config = super()
        # Note: This password is the encrypted form of 'password'. It was generated by the command
        # 'eyaml encrypt -s 'password' --pkcs7-private-key=./spec/support/common/hiera-eyaml/private_key.pkcs7.pem --pkcs7-public-key=./spec/support/common/hiera-eyaml/public_key.pkcs7.pem'
        default_config['password'] = encrypted_password
        default_config
      end

      include_context 'setup hiera-eyaml'

      context 'that contains whitespace characters' do
        let(:encrypted_password) do
          <<-PASSWORD
ENC[PKCS7,MIIBeQYJKoZIhvcNAQcDoIIBajCCAWYCAQAxggEhMIIBHQIBADAFMAACAQEw
DQYJKoZIhvcNAQEBBQAEggEAH8eSYQ6IFtQ9slSgOmXdO0BDzvWwR5suW6Rg
7IGno9KzA7wkG+9aajD+bHj2WGu6eZXuea1YEj+WSXOryrdtqRB4aQf4Dec6
O6u9ERwKdZde4VCyr2b2MUE8KOkxbl3lsZbmqtzlDKVRJ2qE7VKg96VHj0+D
6rYxE2WH8ZADyZVnPo1OjERgEo0prLn851xvd0zhVnp/a2k4KS//y5+Msvdb
TZ/hD4tw8Kt9yHTkTkFKxbmehxdjLUHD7sluB+mw+2ndrXXLASNnRLibH9NS
Xgp69qqO7APnvd9pN7NETS85IkyZW5xTotmz3dgdm+5vaylisWe54yC9pp03
Aba+DTA8BgkqhkiG9w0BBwEwHQYJYIZIAWUDBAEqBBBPxWYPexsOefa7TLOa
lqsUgBAYxyFLFLpVsGxI4XLR8hxD]
          PASSWORD
        end

        it 'decrypts the password' do
          expect(ServiceNowRequest).to receive(:new).with(anything, anything, anything, 'admin', 'password', 'oauth_token', anything)
          expect { servicenow('example.puppet.com') }.to raise_error(NoMethodError)
        end
      end

      context 'that does not contain whitespace characters' do
        let(:encrypted_password) do
          'ENC[PKCS7,MIIBeQYJKoZIhvcNAQcDoIIBajCCAWYCAQAxggEhMIIBHQIBADAFMAACAQEwDQYJKoZIhvcNAQEBBQAEggEAH8eSYQ6IFtQ9slSgOmXdO0BDzvWwR5suW6Rg7IGno9KzA7wkG+9aajD+bHj2WGu6eZXuea1YEj+WSXOryrdtqRB4aQf4Dec6O6u9ERwKdZde4VCyr2b2MUE8KOkxbl3lsZbmqtzlDKVRJ2qE7VKg96VHj0+D6rYxE2WH8ZADyZVnPo1OjERgEo0prLn851xvd0zhVnp/a2k4KS//y5+MsvdbTZ/hD4tw8Kt9yHTkTkFKxbmehxdjLUHD7sluB+mw+2ndrXXLASNnRLibH9NSXgp69qqO7APnvd9pN7NETS85IkyZW5xTotmz3dgdm+5vaylisWe54yC9pp03Aba+DTA8BgkqhkiG9w0BBwEwHQYJYIZIAWUDBAEqBBBPxWYPexsOefa7TLOalqsUgBAYxyFLFLpVsGxI4XLR8hxD]'
        end

        it 'decrypts the password' do
          expect(ServiceNowRequest).to receive(:new).with(anything, anything, anything, 'admin', 'password', 'oauth_token', anything)
          expect { servicenow('example.puppet.com') }.to raise_error(NoMethodError)
        end
      end
    end

    context 'with hiera-eyaml encrypted oauth_token' do
      # Note: This oauth_token is the encrypted form of 'oauth_token'. It was generated by the command
      # 'eyaml encrypt -s 'oauth_token' --pkcs7-private-key=./spec/support/files/private_key.pkcs7.pem --pkcs7-public-key=./spec/support/files/public_key.pkcs7.pem'
      let(:encrypted_oauth_token) do
        'ENC[PKCS7,MIIBeQYJKoZIhvcNAQcDoIIBajCCAWYCAQAxggEhMIIBHQIBADAFMAACAQEwDQYJKoZIhvcNAQEBBQAEggEAKVAUJvBJGrG25SGq0oVymzCxlQ3rvnqNHvl4rKagNshNDe0FKXUxDv0lz/DuklYMTFnKrm8gZxNESvr35ecBM2FckDy1NkIaWWKVFMg5H7KuZaCN/mFgtEpwUkUl3yJpcoJsfN4FpdCWAwjLF1qdOQ25nMEB9sKezZUKMjKm0pnGslr2Gj35HTTxc78HgT9cgVZHi5+NefFlMHDUZWyuSeL4xr4msUFDn6F1RoJp8zYPz31kBMgbowTNxICJV4vX8plwNgLcJicuqeOsEkznO/1bc+fh2yyiAUqimwctd20oni6eubkV8JY5wxfETX+GOiHuHCYZPFemTXHxl3O/GTA8BgkqhkiG9w0BBwEwHQYJYIZIAWUDBAEqBBBl5Z3XF8s8RfEEGTDABqwDgBAadR7I9hBGLSC0m5Ut6xzo]'
      end
      let(:config) do
        default_config = super()
        default_config['oauth_token'] = encrypted_oauth_token
        default_config
      end

      include_context 'setup hiera-eyaml'

      it 'decrypts the oauth_token' do
        expect(ServiceNowRequest).to receive(:new).with(anything, anything, anything, 'admin', 'password', 'oauth_token', anything)
        expect { servicenow('example.puppet.com') }.to raise_error(NoMethodError)
      end
    end
  end
end
