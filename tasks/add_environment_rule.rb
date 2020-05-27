#!/opt/puppetlabs/puppet/bin/ruby
# rubocop:disable Style/GuardClause

# Note that when the unit tests load this script, the CWD
# is the project root. This is why File.exist? starts from
# spec instead of ../spec. However, the script's in the
# tasks directory so we need to start from "../spec" when
# specifying dependencies_dir in order for the require_relative
# to work properly.
dependencies_dir = File.exist?('spec/fixtures/modules') ? '../spec/fixtures/modules' : '../..'

require 'puppet'
Puppet.initialize_settings
require_relative "#{dependencies_dir}/ruby_task_helper/files/task_helper.rb"
require_relative "#{dependencies_dir}/node_manager/lib/puppet/util/nc_https.rb"

# Useful constants
VALIDATION_ERROR = 'servicenow_integration.validation'.freeze
CLASSIFIER_ERROR = 'servicenow_integration.classifier'.freeze
AND_OP = 'and'.freeze
OR_OP = 'or'.freeze
BIN_OPS = [AND_OP, OR_OP].freeze

# This task adds the environment rule to the given environment
# groups
class AddEnvironmentRule < TaskHelper
  def task(group_names: nil, **_kwargs)
    group_names = group_names.uniq
    client = Puppet::Util::Nc_https.new

    # Store the groups as a hash of <group_name> => <group_object>
    groups = {}
    begin
      client.get_groups.each do |group|
        next unless group_names.include?(group['name'])
        groups[group['name']] = group
      end
    rescue => e
      raise TaskHelper::Error.new("Failed to get the groups: #{e.message}", CLASSIFIER_ERROR)
    end

    # Check for any nonexistent groups
    nonexistent_groups = []
    group_names.each do |name|
      next if groups.key?(name)
      nonexistent_groups << name
    end
    unless nonexistent_groups.empty?
      raise TaskHelper::Error.new(
        "Passed-in nonexistent groups #{nonexistent_groups.join(', ')}",
        VALIDATION_ERROR,
        nonexistent_groups: nonexistent_groups,
      )
    end

    # Check for any non-Environment group names
    non_environment_groups = []
    groups.each do |name, obj|
      next if obj['environment_trumps']
      non_environment_groups << name
    end
    unless non_environment_groups.empty?
      raise TaskHelper::Error.new(
        "Passed-in non-Environment groups #{non_environment_groups.join(', ')}",
        VALIDATION_ERROR,
        non_environment_groups: non_environment_groups,
      )
    end

    # Check for any groups with invalid rules (within the task's context, _not_ PE's).
    # An invalid rule is either an API-managed rule ("and"/"or" rule with at least one
    # "and"/"or" child) OR an "and"-rule.
    groups_with_invalid_rules = {}
    groups.each do |name, obj|
      rule = obj['rule']
      next if rule.nil?
      next unless BIN_OPS.include?(rule[0])

      # Check if the rule's API-managed
      rule[1..-1].each do |child|
        next unless BIN_OPS.include?(child[0])
        groups_with_invalid_rules[name] = 'api_managed'
      end

      # Check if the rule's an "and"-rule
      next unless rule[0] == AND_OP
      groups_with_invalid_rules[name] ||= 'and_rule'
    end
    unless groups_with_invalid_rules.empty?
      groups_with_invalid_rules_tuple = groups_with_invalid_rules.map do |group, reason|
        "'#{group}' (#{reason})"
      end

      raise TaskHelper::Error.new(
        "Invalid rule detected in groups #{groups_with_invalid_rules_tuple.join(', ')}",
        VALIDATION_ERROR,
        groups_with_invalid_rules,
      )
    end

    # All the groups have valid rules that are either empty, an atom, or of the form
    # ["or", <atom>...] where "..." means "one-or-more atoms". Here we go ahead and
    # add the environment rule.
    failed_groups = {}
    groups.each do |name, obj|
      rule = obj['rule']
      env_rule = ['=', ['trusted', 'external', 'servicenow', 'puppet_environment'], obj['environment']]

      # First, check if the rule's already been added to ensure idempotency.
      unless rule.nil?
        rule_added = false
        if rule == env_rule
          rule_added = true
        else
          rule[1..-1].each do |child|
            next unless child == env_rule
            rule_added = true
            break
          end
        end
        if rule_added
          debug("Skipping the '#{name}' group since it already has the environment rule added")
          next
        end
      end

      # Rule hasn't been added, so go ahead and add it.
      new_rule = if rule.nil?
                   env_rule
                 elsif rule[0] == OR_OP
                   rule.push(env_rule)
                 else
                   # We have an atom so just "OR" the rules together
                   ['or', rule, env_rule]
                 end

      # Now do the actual update
      obj['rule'] = new_rule
      begin
        client.update_group(obj)
      rescue => e
        failed_groups[name] = e.message
      end
    end
    unless failed_groups.empty?
      raise TaskHelper::Error.new(
        "Failed to add the environment rule to groups #{failed_groups.keys.join(', ')}",
        CLASSIFIER_ERROR,
        failed_groups,
      )
    end

    # Done
  end
end

if $PROGRAM_NAME == __FILE__
  AddEnvironmentRule.run
end
