require 'spec_helper_acceptance'

describe 'trusted external data ($trusted.external.servicenow hash)' do
  let(:params) do
    servicenow_config = servicenow_instance.bolt_config['remote']

    {
      instance: 'acceptance_servicenow_1:1080',
      user: servicenow_config['user'],
      password: servicenow_config['password'],
    }
  end
  let(:setup_manifest) do
    to_manifest(declare('Service', 'pe-puppetserver'), declare('class', 'servicenow_cmdb_integration', params))
  end

  after(:all) do
    set_sitepp_content('')
  end

  # Tests may have test-specific parameters for the servicenow_cmdb_integration
  # class so make sure to apply the class _before_ each test
  before(:each) do
    master.apply_manifest(setup_manifest)
  end

  it 'has idempotent setup' do
    master.apply_manifest(setup_manifest, catch_changes: true)
  end

  shared_context 'setup cmdb' do |cmdb_table = 'cmdb_ci', certname_field = 'fqdn'|
    before(:all) do
      master.run_shell('mkdir -p /opt/puppetlabs/server/data/code-manager/code/environments/production/manifests')
      manifest = <<-MANIFEST
        $trusted_json = inline_template("<%= @trusted.to_json %>")
        notify { "trusted external data":
          message => "#{TRUSTED_JSON_SEPARATOR}${trusted_json}#{TRUSTED_JSON_SEPARATOR}"
        }
      MANIFEST
      set_sitepp_content(manifest)
    end

    before(:each) do
      fields_template = JSON.parse(File.read('spec/support/acceptance/cmdb_record_template.json'))
      # Store the CMDB table in an arbitrary (String) field so that tests can assert on it
      fields_template['attributes'] = cmdb_table
      CMDBHelpers.create_target_record(master, fields_template, table: cmdb_table, certname_field: certname_field)
    end
    after(:each) do
      CMDBHelpers.delete_target_record(master, table: cmdb_table, certname_field: certname_field)
    end
  end

  context 'default behavior' do
    include_context 'setup cmdb'

    it "contains the node's CMDB record in the 'cmdb_ci' table obtained by querying the 'fqdn' field" do
      result = trigger_puppet_run(master)
      trusted_json = parse_trusted_json(result.stdout)
      cmdb_record = CMDBHelpers.get_target_record(master)
      expect(trusted_json['external']['servicenow']).to eql(cmdb_record)
    end
  end

  context 'user specifies a different CMDB table' do
    let(:params) { super().merge('table' => 'cmdb_ci_acc') }

    # NOTE: cmdb_ci_acc is an arbitrary but real table on an actual ServiceNow instance.
    # If for some reason it is changed to something else, then make sure to update the
    # mock ServiceNow instance's implementation with the new table since the mock's
    # available tables are (currently) hardcoded.
    include_context 'setup cmdb', 'cmdb_ci_acc', 'fqdn'

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

    include_context 'setup cmdb', 'cmdb_ci', 'asset_tag'

    it "queries the node's CMDB record using the user-specified certname field" do
      result = trigger_puppet_run(master)
      trusted_json = parse_json(result.stdout, 'trusted_json')
      expected_asset_tag = CMDBHelpers.service_name(master) || master.uri
      expect(trusted_json['external']['servicenow']['asset_tag']).to eql(expected_asset_tag)
    end
  end

  context 'user specifies a hiera-eyaml encrypted password' do

    # before(:all) do
    #   setup_eyaml
    # end

    let(:params) do
      default_params = super()
      password = default_params.delete(:password)
      default_params[:password] = master.run_shell("/opt/puppetlabs/puppet/bin/eyaml encrypt -s #{password} -o string").stdout
      default_params
    end

    include_context 'setup cmdb'

    it 'still works' do
      result = trigger_puppet_run(master)
      trusted_json = parse_json(result.stdout, 'trusted_json')
      expected_asset_tag = CMDBHelpers.service_name(master) || master.uri
      expect(trusted_json['external']['servicenow']['fqdn']).to eql(expected_asset_tag)
    end
  end
end
