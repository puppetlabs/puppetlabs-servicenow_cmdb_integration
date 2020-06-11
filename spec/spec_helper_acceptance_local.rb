# rubocop:disable Style/AccessorMethodName

require './spec/support/acceptance/helpers.rb'

RSpec.configure do |_|
  include TargetHelpers
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

def declare(type, title, params = {})
  params = params.map do |name, value|
    value = "'#{value}'" if value.is_a?(String)
    "  #{name} => #{value},"
  end

  <<-HERE
  #{type} { '#{title}':
  #{params.join("\n")}
  }
  HERE
end

def to_manifest(*declarations)
  declarations.join("\n")
end
