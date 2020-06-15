# rubocop:disable Style/AccessorMethodName

require './spec/support/acceptance/helpers.rb'

RSpec.configure do |c|
  include TargetHelpers

  # Configure all nodes in nodeset
  c.before :suite do
    inventory_hash = LitmusHelpers.inventory_hash_from_inventory_file
    servicenow_instance_uri = servicenow_instance.uri
    servicenow_bolt_config = LitmusHelpers.config_from_node(inventory_hash, servicenow_instance_uri)
    servicenow_config = servicenow_bolt_config['remote']
    manifest = <<-MANIFEST
   class { "servicenow_cmdb_integration":
     instance => "#{servicenow_instance_uri}",
     user     => "#{servicenow_config['user']}",
     password => "#{servicenow_config['password']}",
   }
    MANIFEST

    set_sitepp_content(manifest)
    trigger_puppet_run(master)
    # Test idempotency
    trigger_puppet_run(master, acceptable_exit_codes: [0])
    set_sitepp_content('')
  end
end

# TODO: This will cause some problems if we run the tests
# in parallel. For example, what happens if two targets
# try to modify site.pp at the same time?
def set_sitepp_content(manifest)
  content = <<-HERE
  node default {
    #{manifest}
  }
  HERE

  master.run_shell("echo '#{content}' > /etc/puppetlabs/code/environments/production/manifests/site.pp")
end

def trigger_puppet_run(target, acceptable_exit_codes: [0, 2])
  result = target.run_shell('puppet agent -t --detailed-exitcodes', expect_failures: true)
  unless acceptable_exit_codes.include?(result[:exit_code])
    raise "Puppet run failed\nstdout: #{result[:stdout]}\nstderr: #{result[:stderr]}"
  end
  result
end

TRUSTED_JSON_SEPARATOR = '<TRUSTED_JSON>'.freeze
def parse_trusted_json(puppet_output)
  trusted_json = puppet_output.split(TRUSTED_JSON_SEPARATOR)[1]
  if trusted_json.nil?
    raise "Puppet output does not contain the expected '#{TRUSTED_JSON_SEPARATOR}<trusted_json>#{TRUSTED_JSON_SEPARATOR}' output"
  end
  JSON.parse(trusted_json)
rescue => e
  raise "Failed to parse the trusted JSON: #{e}"
end
