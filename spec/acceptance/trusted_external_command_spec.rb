require 'spec_helper_acceptance'

context 'servicenow_integration::trusted_external_command' do
  before(:all) do
    set_default_api_mock
  end

  before(:each) do
    mockserver.reset_mock_counter(default_endpoint)
  end

  after(:each) do
    set_sitepp_content('')
  end

  context 'apply the class' do
    it 'applies the class without error' do
      idempotent_apply_site_pp(Manifests::ALL_PROPERTIES_DEFINED)
      expect(mockserver.mock_called?(default_endpoint, default_query_params, 24, 24)).to be true
    end

    it 'applies the correct yaml settings' do
      apply_site_pp(Manifests::DEFAULT)
      settings = servicenow_yaml_hash
      expect(settings[:instance]).to          eq('localhost:1080')
      expect(settings[:user]).to              eq('devuser')
      expect(settings[:password]).to          eq('devpass')
      expect(settings[:table]).to             eq('cmdb_ci')
      expect(settings[:certname_field]).to    eq('fqdn')
      expect(settings[:classes_field]).to     eq('u_puppet_classes')
      expect(settings[:environment_field]).to eq('u_puppet_environment')
      expect(mockserver.mock_called?(default_endpoint, default_query_params)).to be true
    end

    it 'applies the correct yaml settings when all properties defined' do
      apply_site_pp(Manifests::ALL_PROPERTIES_DEFINED)
      settings = servicenow_yaml_hash
      expect(settings[:instance]).to          eq('localhost:1080')
      expect(settings[:user]).to              eq('devuser')
      expect(settings[:password]).to          eq('devpass')
      expect(settings[:table]).to             eq('cmdb_ci')
      expect(settings[:certname_field]).to    eq('fqdn')
      expect(settings[:classes_field]).to     eq('u_puppet_classes')
      expect(settings[:environment_field]).to eq('u_puppet_environment')
      expect(mockserver.mock_called?(default_endpoint, default_query_params)).to be true
    end
  end
end
