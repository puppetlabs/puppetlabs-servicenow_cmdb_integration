require 'spec_helper_acceptance'

describe 'trusted external data ($trusted.external.servicenow hash)' do
  let(:params) do
    servicenow_config = servicenow_instance.bolt_config['remote']

    {
      instance: servicenow_instance.uri,
      user: servicenow_config['user'],
      password: servicenow_config['password'],
    }
  end

  let(:invalid_user_params) do
    default_params = params
    default_params[:user] = "invalid_#{default_params[:user]}"
    default_params
  end

  let(:setup_manifest) do
    to_manifest(declare('Service', 'pe-puppetserver'), declare('class', 'servicenow_cmdb_integration', params))
  end

  let(:invalid_user_manifest) do
    to_manifest(declare('Service', 'pe-puppetserver'), declare('class', 'servicenow_cmdb_integration', invalid_user_params))
  end

  before(:all) do
    manifest = <<-MANIFEST
      $trusted_json = inline_template("<%= @trusted.to_json %>")
      notify { "trusted external data":
        message => "#{JSON_SEPARATOR}${trusted_json}#{JSON_SEPARATOR}"
      }
    MANIFEST
    set_sitepp_content(manifest)
  end
  after(:all) do
    set_sitepp_content('')
  end

  it 'has idempotent setup' do
    clear_trusted_external_data_setup
    master.idempotent_apply(setup_manifest)
  end

  shared_context 'trusted external data test setup' do |cmdb_table: 'cmdb_ci', certname_field: 'fqdn'|
    before(:each) do
      CMDBHelpers.delete_target_record(master, table: cmdb_table, certname_field: certname_field)
      # Set up the trusted external command
      master.apply_manifest(setup_manifest, catch_failures: true)

      # Set up the CMDB. Note that we store the CMDB table in an arbitrary (String) field so that tests
      # can assert on it
      fields_template = JSON.parse(File.read('spec/support/acceptance/cmdb_record_template.json'))
      fields_template['attributes'] = cmdb_table
      CMDBHelpers.create_target_record(master, fields_template, table: cmdb_table, certname_field: certname_field)
    end
  end

  context 'default behavior' do
    include_context 'trusted external data test setup'

    it "contains the node's CMDB record in the 'cmdb_ci' table obtained by querying the 'fqdn' field" do
      result = trigger_puppet_run(master)
      trusted_json = parse_json(result.stdout, 'trusted_json')

      cmdb_record = CMDBHelpers.get_target_record(master)
      # Remove the classification fields from the CMDB record since those will
      # be tested separately
      cmdb_record.delete('u_puppet_classes')
      cmdb_record.delete('u_puppet_environment')

      # We use 'include' instead of 'eql' because the 'servicenow' hash includes
      # extra keys that are used to implement node classification. We don't care
      # about those keys. All we care about is that the hash contains the node's
      # CMDB record which is exactly what 'include' tests.
      expect(trusted_json['external']['servicenow']).to include(cmdb_record)
    end
  end

  context 'user specifies a different CMDB table' do
    let(:params) { super().merge('table' => 'cmdb_ci_acc') }

    # NOTE: cmdb_ci_acc is an arbitrary but real table on an actual ServiceNow instance.
    # If for some reason it is changed to something else, then make sure to update the
    # mock ServiceNow instance's implementation with the new table since the mock's
    # available tables are (currently) hardcoded.
    include_context 'trusted external data test setup', cmdb_table: 'cmdb_ci_acc'

    it "contains the node's CMDB record in the user-specified CMDB table" do
      result = trigger_puppet_run(master)
      trusted_json = parse_json(result.stdout, 'trusted_json')
      # The 'default behavior' test already asserts full CMDB equality. Thus
      # to avoid propagating redundant failure messages in case the
      # "full CMDB equality" part of the script fails, it is enough to assert
      # on one expected field to pass this test
      expect(trusted_json['external']['servicenow']['attributes']).to eql('cmdb_ci_acc')
    end
  end

  context 'user specifies a different certname field' do
    # Choose 'asset_tag' as the certname field since it is a String
    let(:params) { super().merge('certname_field' => 'asset_tag') }

    include_context 'trusted external data test setup', certname_field: 'asset_tag'

    it "queries the node's CMDB record using the user-specified certname field" do
      result = trigger_puppet_run(master)
      trusted_json = parse_json(result.stdout, 'trusted_json')
      expect(trusted_json['external']['servicenow']['asset_tag']).to eql(master.uri)
    end
  end

  context 'user specifies a hiera-eyaml encrypted password' do
    let(:params) do
      default_params = super()
      password = default_params.delete(:password)
      default_params[:password] = master.run_shell("/opt/puppetlabs/puppet/bin/eyaml encrypt -s #{password} -o string").stdout
      default_params
    end

    include_context 'trusted external data test setup'

    it 'still works' do
      result = trigger_puppet_run(master)
      trusted_json = parse_json(result.stdout, 'trusted_json')
      expect(trusted_json['external']['servicenow']['fqdn']).to eql(master.uri)
    end
  end

  # This test provides coverage for oauth tokens both encrypted and not.
  context 'user specifies a hiera-eyaml encrypted oauth token' do
    # skip the oauth tests if we don't have a token to test with
    servicenow_config = servicenow_instance.bolt_config['remote']
    skip_oauth_tests = false
    using_mock_instance = servicenow_instance.uri =~ Regexp.new(Regexp.escape(master.uri))
    unless using_mock_instance
      skip_oauth_tests = (servicenow_config['oauth_token']) ? false : true
    end

    puts 'Skipping this test becuase there is no token specified in the test inventory.' if skip_oauth_tests

    let(:params) do
      default_params = super()
      default_params.delete(:user)
      default_params.delete(:password)
      default_params[:oauth_token] = master.run_shell("/opt/puppetlabs/puppet/bin/eyaml encrypt -s #{servicenow_config['oauth_token']} -o string").stdout
      default_params
    end

    include_context 'trusted external data test setup'

    it 'uses the new oauth token', skip: skip_oauth_tests do
      result = trigger_puppet_run(master)
      trusted_json = parse_json(result.stdout, 'trusted_json')
      expect(trusted_json['external']['servicenow']['fqdn']).to eql(master.uri)
    end
  end

  context 'dry testing the servicenow.rb script fails in the trusted external data setup' do
    before(:each) do
      clear_trusted_external_data_setup
    end

    it 'reports an error and does not set the trusted_external_command setting' do
      master.apply_manifest(invalid_user_manifest, expect_failures: true)
      trusted_external_command_setting = master.run_shell('puppet config print trusted_external_command --section master').stdout.chomp
      expect(trusted_external_command_setting).to be_empty
    end
  end

  context 'dry testing changes to a valid configuration' do
    before(:each) do
      clear_trusted_external_data_setup
    end

    include_context 'trusted external data test setup'

    it 'reports an error and does not set the trusted_external_command setting' do
      master.apply_manifest(invalid_user_manifest, expect_failures: true) do |response|
        expect(response['stdout']).to match(%r{File\[/etc/puppetlabs/puppet/servicenow_cmdb\.yaml\] has failures: true})
        expect(response['stderr']).to match(%r{validate_settings\.rb.+returned 1.+Authorization Failed})
      end
    end
  end
end
