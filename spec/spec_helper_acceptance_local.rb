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
    puts 'Validate PE Installed.'
    LitmusHelper.instance.bolt_run_script('spec/support/files/install_pe.sh')
    puts 'Validate Mockserver container running'
    LitmusHelper.instance.bolt_run_script('spec/support/files/run_mockserver_container.sh')
    puts 'Install module on system under test'
    Rake::Task['litmus:install_module'].invoke unless ENV['CI'] == 'true'
  end
end

def module_fixtures
  @module_fixtures ||= File.join(Dir.pwd, 'spec/fixtures/modules')
  @module_fixtures
end

def target_host_facts
  @target_host_facts ||= LitmusHelper.instance.run_bolt_task('facts')[:result]
  @target_host_facts
end

def sudo_idempotent_apply(manifest)
  apply_manifest(manifest, prefix_command: 'sudo', catch_failures: true)
  apply_manifest(manifest, prefix_command: 'sudo', catch_changes: true)
end

def mockserver
  @mockserver ||= Mockserver.new("#{ENV['TARGET_HOST']}:1080")
  @mockserver
end

def run_mock_container
  LitmusHelper.instance.run_shell('')
end

def default_api_response
  file_content = File.read('spec/support/files/valid_api_response.json')
  file_content.gsub('dev84270.service-now.com', "#{ENV['TARGET_HOST']}:1080")
end

def default_endpoint
  '/api/now/table/'
end

def default_query_params
  {
    fqdn: ENV['TARGET_HOST'],
    sysparm_display_value: 'true',
  }
end
