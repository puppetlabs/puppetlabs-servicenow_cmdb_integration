require 'puppet_litmus'
# rubocop:disable Style/BracesAroundHashParameters

# The Target class and TargetHelpers module are a useful ways
# for tests to reuse Litmus' helpers when they want to do stuff
# on nodes that may not be the current target host (like e.g.
# the master or the ServiceNow instance).
#
# NOTE: The code here is Litmus' recommended approach for multi-node
# testing (see https://github.com/puppetlabs/puppet_litmus/issues/72).
# We should revisit it once Litmus has a standardized pattern for
# multi-node testing.

class Target
  include PuppetLitmus

  attr_reader :uri

  def initialize(uri)
    @uri = uri
  end

  def bolt_config
    inventory_hash = LitmusHelpers.inventory_hash_from_inventory_file
    LitmusHelpers.config_from_node(inventory_hash, @uri)
  end

  # Make sure that ENV['TARGET_HOST'] is set to uri
  # before each PuppetLitmus method call. This makes it
  # so if we have an array of targets, say 'agents', then
  # code like agents.each { |agent| agent.bolt_upload_file(...) }
  # will work as expected. Otherwise if we do this in, say, the
  # constructor, then the code will only work for the agent that
  # most recently set the TARGET_HOST variable.
  PuppetLitmus.instance_methods.each do |name|
    m = PuppetLitmus.instance_method(name)
    define_method(name) do |*args, &block|
      ENV['TARGET_HOST'] = uri
      m.bind(self).call(*args, &block)
    end
  end
end

class TargetNotFoundError < StandardError; end
module TargetHelpers
  def master
    target('master', 'acceptance:provision_vms', 'master')
  end
  module_function :master

  def servicenow_instance
    target('ServiceNow instance', 'acceptance:setup_servicenow_instance', 'servicenow_instance')
  end
  module_function :servicenow_instance

  def target(name, setup_task, role)
    @targets ||= {}

    unless @targets[name]
      # Find the target
      inventory_hash = LitmusHelpers.inventory_hash_from_inventory_file
      targets = LitmusHelpers.find_targets(inventory_hash, nil)
      target_uri = targets.find do |target|
        vars = LitmusHelpers.vars_from_node(inventory_hash, target) || {}
        roles = vars['roles'] || []
        roles.include?(role)
      end
      unless target_uri
        raise TargetNotFoundError, "none of the targets in 'inventory.yaml' have the '#{role}' role set. Did you forget to run 'rake #{setup_task}'?"
      end
      @targets[name] = Target.new(target_uri)
    end

    @targets[name]
  end
  module_function :target
end

module LitmusHelpers
  extend PuppetLitmus
end

# These are helpers for ServiceNow's CMDB

class CMDBRecordRetrievalError < StandardError; end
module CMDBHelpers
  extend TargetHelpers

  def create_target_record(target, fields, table: 'cmdb_ci', certname_field: 'fqdn')
    record = get_target_record(target, table: table, certname_field: certname_field)
    unless record.nil?
      raise "On #{servicenow_instance.uri} with table = #{table}, certname_field = #{certname_field}, a record already exists for #{target.uri}: #{record['sys_id']}"

    end
    task_result = servicenow_instance.run_bolt_task(
      'servicenow_tasks::create_record',
      { 'table' => table, 'fields' => fields.merge(certname_field => target.uri) }
    )
    task_result.result['result']
  end
  module_function :create_target_record

  def get_target_record(target, table: 'cmdb_ci', certname_field: 'fqdn')
    task_result = servicenow_instance.run_bolt_task(
      'servicenow_tasks::get_records',
      { 'table' => table, 'url_params' => { certname_field => target.uri, 'sysparm_display_value' => true } },
    )
    satisfying_records = task_result.result['result']
    return nil if satisfying_records.empty?
    if satisfying_records.length > 1
      sys_ids = satisfying_records.map do |record|
        record['sys_id']
      end
      raise "On #{servicenow_instance.uri} with table = #{table}, certname_field = #{certname_field}, more than one record exists for #{target.uri}: #{sys_ids.join(', ')}"
    end
    satisfying_records.first
  end
  module_function :get_target_record

  def delete_target_record(target, table: 'cmdb_ci', certname_field: 'fqdn')
    record = get_target_record(target, table: table, certname_field: certname_field)
    return if record.nil?
    servicenow_instance.run_bolt_task(
      'servicenow_tasks::delete_record',
      { 'table' => table, 'sys_id' => record['sys_id'] },
    )
  end
  module_function :delete_target_record
end
