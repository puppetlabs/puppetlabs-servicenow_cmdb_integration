require 'spec_helper_acceptance'
require 'json'

describe 'node classification' do
  let(:params) do
    servicenow_config = servicenow_instance.bolt_config['remote']

    {
      instance: servicenow_instance.uri,
      user: servicenow_config['user'],
      password: servicenow_config['password'],
    }
  end

  # Unfortunately, let(...) is only allowed for 'it'/'before(:each)'/'after(:each)'
  # blocks. Since these are also used in 'before(:all)'/'after(:all)' blocks, we
  # make these constants instead.
  TEST_ENVIRONMENT = 'node_classification_tests'.freeze
  TEST_ENVIRONMENT_CODE_DIR = "/etc/puppetlabs/code/environments/#{TEST_ENVIRONMENT}".freeze

  before(:all) do
    # Setup the test environment. Here are the steps:
    #   * Upload our minimized control repo to the test environment's code directory
    #
    #   * 'Install' the servicenow_cmdb_integration module into our environment's
    #     modules directory by making it a symlink to production's modules directory.
    #     This way, our test environment's version of the servicenow_cmdb_integration
    #     module matches what we're testing.
    #
    #   * Create the test environment's environment group in the classifier
    #
    #   * Add the environment matching rule via the add_environment_rule task
    master.bolt_upload_file('spec/support/acceptance/control_repo', TEST_ENVIRONMENT_CODE_DIR)
    setup_manifest = to_manifest(
      declare(
        'File',
        "#{TEST_ENVIRONMENT_CODE_DIR}/modules",
        ensure: 'link',
        target: '/etc/puppetlabs/code/environments/production/modules',
      ),
      declare(
        'node_group',
        TEST_ENVIRONMENT,
        ensure: 'present',
        parent: 'All Environments',
        environment: TEST_ENVIRONMENT,
        override_environment: true,
      ),
    )
    master.apply_manifest(setup_manifest, catch_failures: true)
    master.run_shell("puppet task run servicenow_cmdb_integration::add_environment_rule --params '{\"group_names\": [\"#{TEST_ENVIRONMENT}\"]}' --nodes #{master.uri}")
  end
  after(:all) do
    # Teardown the test environment
    master.run_shell("rm -rf #{TEST_ENVIRONMENT_CODE_DIR}")
    master.apply_manifest(declare('node_group', TEST_ENVIRONMENT, ensure: 'absent'), catch_failures: true)
    CMDBHelpers.delete_target_record(master)
  end

  # Setup the trusted external data feature since classification depends on it.
  # Note that tests may have test-specific parameters for the servicenow_cmdb_integration
  # class so we apply the class _before_ each test.
  before(:each) do
    setup_manifest = to_manifest(
      declare('Service', 'pe-puppetserver'),
      declare('class', 'servicenow_cmdb_integration', params),
    )
    master.apply_manifest(setup_manifest, catch_failures: true)
  end

  shared_examples 'classification tests' do |classes_field: 'u_puppet_classes', environment_field: 'u_puppet_environment'|
    let(:classes) do
      {
        'no_param' => {},
        'single_param' => {
          'param' => 'param_value',
        },
        'multiple_params' => {
          'param_one' => 'param_one_value',
          'param_two' => 'param_two_value',
        },
      }
    end

    before(:each) do
      CMDBHelpers.delete_target_record(master)
      fields_template = JSON.parse(File.read('spec/support/acceptance/cmdb_record_template.json'))
      fields_template[classes_field] = classes.to_json
      fields_template[environment_field] = TEST_ENVIRONMENT
      CMDBHelpers.create_target_record(master, fields_template)
    end

    it "lets users classify nodes in ServiceNow's CMDB" do
      # Note that the control repo's site.pp will be applied on the node
      # (assuming environment classification works)
      result = trigger_puppet_run(master)
      classification_json = nil
      begin
        classification_json = parse_json(result.stdout, 'classification_json')
      rescue => e
        raise "#{e}\nWas the node's environment set to '#{TEST_ENVIRONMENT}' so that the control repo's site.pp was applied?"
      end
      expected_classification_json = {
        'environment' => TEST_ENVIRONMENT,
        'classes' => classes,
      }
      expect(classification_json).to eql(expected_classification_json)
    end
  end

  context 'default behavior' do
    # TODO: This test requires the 'u_puppet_classes' and 'u_puppet_environment' fields
    # to be present on a real ServiceNow instance. Might be worth adding some code in
    # the setup tasks to ensure that those fields exist (and to create them if they don't).
    include_examples 'classification tests'
  end

  context 'user specifies a different classes field' do
    # Choose 'comments' since it is a String and its max length is
    # long enough to accept all of our inputs
    let(:params) { super().merge('classes_field' => 'comments') }

    include_examples 'classification tests', classes_field: 'comments'
  end

  context 'user specifies a different environment field' do
    let(:params) { super().merge('environment_field' => 'comments') }

    include_examples 'classification tests', environment_field: 'comments'
  end

  context 'classes field is a Name-Value pairs field type' do
    let(:params) { super().merge('classes_field' => 'u_puppet_classes_nvp') }

    # Note that the ServiceNow API accepts a JSON object (raw or encoded) as input when
    # updating a Name-Value pairs field. The API takes this JSON object and stringifies its
    # values (so {"foo": {}} is stored as {"foo": "{}"}. Thus, our existing setup is still
    # valid so we can reuse the 'classification tests' example.
    include_examples 'classification tests', classes_field: 'u_puppet_classes_nvp'
  end
end
