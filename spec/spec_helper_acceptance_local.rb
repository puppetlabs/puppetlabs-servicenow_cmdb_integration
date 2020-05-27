require 'puppet_litmus'
require 'singleton'
require 'puppet_litmus/rake_tasks' if Bundler.rubygems.find_name('puppet_litmus').any?
require 'support/mockserver/helpers'
require 'support/manifest_strings'
require 'yaml'

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

def idempotent_apply_site_pp(manifest)
  sitepp_content(manifest)

  first_apply = run_shell('sudo puppet agent -t --detailed-exitcodes', expect_failures: true)
  raise "stdout: #{first_apply[:stdout]}\nstderr: #{first_apply[:stderr]}" unless [0, 2].include?(first_apply[:exit_code])

  second_apply = run_shell('sudo puppet agent -t --detailed-exitcodes', expect_failures: true)
  raise "stdout: #{second_apply[:stdout]}\nstderr: #{second_apply[:stderr]}" unless second_apply[:exit_code] == 0
end

def apply_site_pp(manifest)
  sitepp_content(manifest)

  apply_result = run_shell('sudo puppet agent -t --detailed-exitcodes', expect_failures: true)
  raise "stdout: #{apply_result[:stdout]}\nstderr: #{apply_result[:stderr]}" unless [0, 2].include?(apply_result[:exit_code])
end

def mockserver
  @mockserver ||= Mockserver.new("#{ENV['TARGET_HOST']}:1080")
  @mockserver
end

def set_default_api_mock
  mockserver.set(default_endpoint, default_api_response, default_query_params)
end

def default_api_response
  file_content = File.read('spec/support/files/valid_api_response.json')
  file_content.gsub('dev84270.service-now.com', "#{ENV['TARGET_HOST']}:1080")
end

def default_endpoint
  '/api/now/table/cmdb_ci'
end

def default_query_params
  {
    fqdn: ENV['TARGET_HOST'],
    sysparm_display_value: 'true',
  }
end

def servicenow_yaml_hash
  yaml = run_shell('cat /etc/puppetlabs/puppet/servicenow.yaml')
  YAML.safe_load(yaml[:stdout], symbolize_names: true)
end

def sitepp_content(manifest)
  content = <<-HERE
  node default {
    #{manifest}
  }
  HERE

  run_shell("echo '#{content}' > /etc/puppetlabs/code/environments/production/manifests/site.pp")
end
