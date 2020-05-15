# frozen_string_literal: true

RSpec.configure do |c|
  # Use rspec mocks instead of mocha as per https://github.com/puppetlabs/puppetlabs_spec_helper#mock_with
  # This configuration must be specified before the puppetlabs_spec_helper gem is loaded to avoid
  # the deprecation warning.
  c.mock_with :rspec
end

require 'puppetlabs_spec_helper/module_spec_helper'
require 'rspec-puppet-facts'

require 'spec_helper_local' if File.file?(File.join(File.dirname(__FILE__), 'spec_helper_local.rb'))

include RspecPuppetFacts

default_facts = {
  puppetversion: Puppet.version,
  facterversion: Facter.version,
}

default_fact_files = [
  File.expand_path(File.join(File.dirname(__FILE__), 'default_facts.yml')),
  File.expand_path(File.join(File.dirname(__FILE__), 'default_module_facts.yml')),
]

default_fact_files.each do |f|
  next unless File.exist?(f) && File.readable?(f) && File.size?(f)

  begin
    default_facts.merge!(YAML.safe_load(File.read(f), [], [], true))
  rescue => e
    RSpec.configuration.reporter.message "WARNING: Unable to load #{f}: #{e}"
  end
end

# read default_facts and merge them over what is provided by facterdb
default_facts.each do |fact, value|
  add_custom_fact fact, value
end

# According to https://github.com/rodjek/rspec-puppet/issues/626, the current
# rspec-puppet way of testing code that uses Hiera data is to add all the backends
# to the module's hiera.yaml file. This is not a good idea. Instead, we use a slightly
# tweaked version of the workaround specified in
# https://github.com/rodjek/rspec-puppet/issues/626#issuecomment-415597902 to use
# spec/fixtures/hiera.yaml. Note that I monkey-patch GlobalDataProvider instead
# of ModuleDataProvider because the latter doesn't work.
class Puppet::Pops::Lookup::GlobalDataProvider
  def configuration_path(_lookup_invocation)
    Pathname.new(File.expand_path(File.join(File.dirname(__FILE__), 'fixtures', 'hiera.yaml')))
  end
end

RSpec.configure do |c|
  c.default_facts = default_facts
  c.before :each do
    # set to strictest setting for testing
    # by default Puppet runs at warning level
    Puppet.settings[:strict] = :warning
  end
  c.filter_run_excluding(bolt: true) unless ENV['GEM_BOLT']
  c.after(:suite) do
  end
  # Doing this prevents paths like "../../../" for task unit tests
  $LOAD_PATH << 'tasks'
end

# Ensures that a module is defined
# @param module_name Name of the module
def ensure_module_defined(module_name)
  module_name.split('::').reduce(Object) do |last_module, next_module|
    last_module.const_set(next_module, Module.new) unless last_module.const_defined?(next_module, false)
    last_module.const_get(next_module, false)
  end
end

# 'spec_overrides' from sync.yml will appear below this line
