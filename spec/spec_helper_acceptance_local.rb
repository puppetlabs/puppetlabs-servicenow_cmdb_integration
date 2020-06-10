# rubocop:disable Style/AccessorMethodName

require './spec/support/acceptance/helpers.rb'

RSpec.configure do |_|
  include TargetHelpers
end

# TODO: This will cause some problems if we run the tests
# in parallel. For example, what happens if two targets
# try to modify site.pp at the same time?
def set_sitepp_content(manifest)
  site_pp_path = '/opt/puppetlabs/server/data/code-manager/code/environments/production/manifests/site.pp'

  content = <<-HERE
  node default {
    #{manifest}
  }
  HERE

  Tempfile.open('manifest') do |f|
    f.write(content)
    f.flush
    master.bolt_upload_file(f.path, site_pp_path)
    f.unlink
  end
  master.run_shell("chown pe-puppet:pe-puppet #{site_pp_path}")
  master.run_shell('puppetserver reload')
end

def trigger_puppet_run(target, acceptable_exit_codes: [0, 2])
  result = target.run_shell('puppet agent -t --detailed-exitcodes', expect_failures: true)
  unless acceptable_exit_codes.include?(result[:exit_code])
    raise "Puppet run failed\nstdout: #{result[:stdout]}\nstderr: #{result[:stderr]}"
  end
  result
end

JSON_SEPARATOR = '<JSON>'.freeze
def parse_json(puppet_output, desc)
  raw_json = puppet_output.split(JSON_SEPARATOR)[1]
  if raw_json.nil?
    raise "Puppet output does not contain the expected '#{JSON_SEPARATOR}<#{desc}>#{JSON_SEPARATOR}' output"
  end
  JSON.parse(raw_json)
rescue => e
  raise "Failed to parse the #{desc} JSON: #{e}\nPuppet output:\n#{puppet_output}"
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

def setup_eyaml
  master.run_shell('mkdir -p /etc/eyaml')
  master.bolt_upload_file('spec/support/common/hiera-eyaml/private_key.pkcs7.pem', '/etc/eyaml/private_key.pkcs7.pem')
  master.bolt_upload_file('spec/support/common/hiera-eyaml/public_key.pkcs7.pem', '/etc/eyaml/public_key.pkcs7.pem')
  master.bolt_upload_file('spec/support/common/hiera-eyaml/config.yaml', '/etc/eyaml/config.yaml')
  master.run_shell('chown -R pe-puppet:pe-puppet /etc/eyaml')
  master.run_shell('chmod -R 0500 /etc/eyaml')
  master.run_shell('chmod 0400 /etc/eyaml/*.pem')
end
