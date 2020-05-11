require 'spec_helper'
require 'support/add_environment_rule_spec_helpers'

require 'add_environment_rule'

describe 'add_environment_rule' do
  subject(:klass) { AddEnvironmentRule.new }

  let(:groups) { JSON.parse(File.read('./spec/support/tasks/groups.json')) }
  let(:client) do
    instance_double('Puppet::Util::Nc_https')
  end

  before(:each) do
    # Place the common mocks here
    allow(Puppet::Util::Nc_https).to receive(:new).and_return(client)
    allow(client).to receive(:get_groups).and_return(groups.values)
  end

  it 'raises an error if it fails to get the groups' do
    allow(client).to receive(:get_groups).and_raise('api_failed')

    expect { klass.task(group_names: ['one_name']) }.to raise_error do |e|
      assert_task_error(e, %r{groups.*api_failed}, CLASSIFIER_ERROR)
    end
  end

  it 'raises an error for nonexistent groups' do
    expect { klass.task(group_names: ['one_name', 'foo', 'two_name', 'bar']) }.to raise_error do |e|
      assert_task_error(e, %r{nonexistent.*foo.*bar}, VALIDATION_ERROR, nonexistent_groups: ['foo', 'bar'])
    end
  end

  it 'raises an error for non-Environment groups' do
    groups['two_name']['environment_trumps'] = false
    groups['four_name']['environment_trumps'] = false
    expect { klass.task(group_names: ['one_name', 'two_name', 'three_name', 'four_name']) }.to raise_error do |e|
      assert_task_error(e, %r{non-Environment.*two_name.*four_name}, VALIDATION_ERROR, non_environment_groups: ['two_name', 'four_name'])
    end
  end

  it 'raises an error for groups with invalid rules' do
    atom = ['=', ['fact', 'foo'], 'bar']

    # These groups have valid rules
    groups['one_name']['rule'] = nil
    groups['three_name']['rule'] = atom
    groups['five_name']['rule'] = ['or', atom, atom]

    # These groups have invalid rules (API-managed)
    groups['two_name']['rule'] = ['and', ['and', atom], atom]
    groups['four_name']['rule'] = ['and', atom, ['or', atom, atom]]
    groups['six_name']['rule'] = ['or', ['and', atom], atom]
    groups['seven_name']['rule'] = ['or', atom, ['or', atom, atom]]

    # These groups also have invalid rules ("and"-rule)
    groups['eight_name']['rule'] = ['and', atom]

    group_names = [
      'one_name',
      'two_name',
      'three_name',
      'four_name',
      'five_name',
      'six_name',
      'seven_name',
      'eight_name',
    ]
    expect { klass.task(group_names: group_names) }.to raise_error do |e|
      msg_regex = %r{rule.*two_name.*four_name.*six_name.*seven_name.*eight_name}
      details = {
        'two_name'   => 'api_managed',
        'four_name'  => 'api_managed',
        'six_name'   => 'api_managed',
        'seven_name' => 'api_managed',
        'eight_name' => 'and_rule',
      }
      assert_task_error(e, msg_regex, VALIDATION_ERROR, details)
    end
  end

  context 'valid groups' do
    let(:atom) { ['=', ['fact', 'foo'], 'bar'] }
    let(:group_names) { ['one_name', 'two_name', 'three_name'] }

    before(:each) do
      groups['one_name']['rule'] = nil
      groups['two_name']['rule'] = atom
      groups['three_name']['rule'] = ['or', atom]
    end

    it 'adds the environment rule to the specified groups' do
      expected_rules = {
        'one_id'   => construct_env_rule('one_environment'),
        'two_id'   => ['or', atom, construct_env_rule('two_environment')],
        'three_id' => ['or', atom, construct_env_rule('three_environment')],
      }

      expect(client).to receive(:update_group).exactly(3).times do |group|
        expect(group['rule']).to eql(expected_rules[group['id']])
      end

      klass.task(group_names: group_names)
    end

    it 'raises an error if it fails to add the environment rule to some of the groups' do
      allow(client).to receive(:update_group) do |group|
        raise "#{group['name']} failed" if ['one_name', 'three_name'].include?(group['name'])
      end

      expect { klass.task(group_names: group_names) }.to raise_error do |e|
        details = {
          'one_name'   => 'one_name failed',
          'three_name' => 'three_name failed',
        }
        assert_task_error(e, %r{env.*rule.*one_name.*three_name}, CLASSIFIER_ERROR, details)
      end
    end

    it 'enforces idempotency' do
      groups['two_name']['rule'] = construct_env_rule('two_environment')
      groups['three_name']['rule'] = ['or', atom, construct_env_rule('three_environment'), atom]
      # Note that one_name's rule remains unchanged

      expect(client).to receive(:update_group).exactly(1).times do |group|
        raise 'wrong group!' unless group['name'] == 'one_name'
      end

      klass.task(group_names: group_names)
    end
  end
end
