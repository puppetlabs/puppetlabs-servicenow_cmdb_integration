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

def idempotent_apply_site_pp(manifest)
  # Since we are testing a feature of the puppet master, we cannot use the standard litmus apply_catalog function
  # which creates a standalone manifest file and calls Puppet apply against the path of the manifest.
  # We need the master to compile a catalog for the node, in this case itself. To do that we set the contents
  # of the site.pp file and call puppet agent -t
  sitepp_content(manifest)

  # When running on CI platforms like Travis, calling puppet agent -t without sudo causes the run to fail because
  # this module manages file owned by Puppet.
  first_apply = run_shell('sudo puppet agent -t --detailed-exitcodes', expect_failures: true)
  raise "stdout: #{first_apply[:stdout]}\nstderr: #{first_apply[:stderr]}" unless [0, 2].include?(first_apply[:exit_code])

  second_apply = run_shell('sudo puppet agent -t --detailed-exitcodes', expect_failures: true)
  raise "stdout: #{second_apply[:stdout]}\nstderr: #{second_apply[:stderr]}" unless second_apply[:exit_code] == 0
end

def apply_site_pp(manifest)
  sitepp_content(manifest)

  apply_result = run_shell('sudo puppet agent -t --detailed-exitcodes', expect_failures: true)
  raise "stdout: #{apply_result[:stdout]}\nstderr: #{apply_result[:stderr]}" unless [0, 2].include?(apply_result[:exit_code])
  block_given? ? yield(apply_result) : apply_result
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

def capture_trusted_notice(report)
  # If you apply the Manifests::TRUSTED_EXTERNAL_VARIABLE manifest it will emit a notice
  # that will contain the contents of the $trusted variable. This function will capture
  json_regex = %r{defined 'message' as '(?<trusted_json>.+)'}

  matches = report[:stdout].match(json_regex)
  raise 'trusted external json content not found' if matches.nil?
  parsed_data = JSON.parse(matches[:trusted_json], symbolize_names: true)
  parsed_data.dig :external, :servicenow
end
