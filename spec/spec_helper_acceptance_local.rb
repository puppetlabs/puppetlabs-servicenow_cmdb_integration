require 'puppet_litmus'
require 'singleton'
require 'puppet_litmus/rake_tasks' if Bundler.rubygems.find_name('puppet_litmus').any?
require 'support/mockserver/helpers'
require 'support/manifest_strings'

# automatically load any shared examples or contexts
Dir['./spec/support/**/*.rb'].sort.each { |f| require f }

class LitmusHelper
  include Singleton
  include PuppetLitmus
end

RSpec.configure do |c|
  # Configure all nodes in nodeset
  c.before :suite do
    unless ENV['CI'] == 'true' || ENV['PROVISION_PE'] == 'false'
      puts 'Begin PE Install. Grab a snack. This could take a while.'
      _scriptOutput = LitmusHelper.instance.bolt_run_script('spec/support/files/install_pe.sh')
      puts 'Begin container download and run'
      LitmusHelper.instance.bolt_run_script('spec/support/files/run_mockserver_container.sh')
      puts 'Install module on system under test'
      Rake::Task['litmus:install_module'].invoke
    end
  end
end

def module_fixtures
  @module_fixtures ||= File.join(Dir.pwd, 'spec/fixtures/modules')
end

def target_host_facts
  @target_host_facts ||= LitmusHelper.instance.run_bolt_task('facts')[:result]
end

def sudo_idempotent_apply(manifest)
    apply_manifest(manifest, prefix_command: 'sudo', catch_failures: true)
    apply_manifest(manifest, prefix_command: 'sudo', catch_changes: true)
end
