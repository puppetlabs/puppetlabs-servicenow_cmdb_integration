require 'spec_helper_acceptance'

context 'servicenow_integration::trusted_external_command' do
  before(:all) do
    mockserver.set(default_endpoint, default_api_response, default_query_params)
  end

  context 'apply the class' do
    let(:default_manifest) do
      <<-HERE
      class {'servicenow_integration::trusted_external_command':
          instance => 'localhost:1080',
          user     => 'devuser',
          password => 'devpass',
      }
      HERE
    end

    it 'applies the class without error' do
      sudo_idempotent_apply(default_manifest)
      mockserver.assert_mock_called(default_endpoint, default_query_params)
    end
  end
end
