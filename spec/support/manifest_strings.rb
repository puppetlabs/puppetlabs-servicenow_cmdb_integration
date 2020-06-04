class Manifests
  # Double quotes are used in these manifests because the singles get lost when
  # Litmus transfers the commend to the host under test.
  DEFAULT = <<-HERE.freeze
  class {"servicenow_cmdb_integration::trusted_external_command":
    instance => "localhost:1080",
    user     => "devuser",
    password => "devpass",
  }
  HERE

  ALL_PROPERTIES_DEFINED = <<-HERE.freeze
  class {"servicenow_cmdb_integration::trusted_external_command":
    instance          => "localhost:1080",
    user              => "devuser",
    password          => "devpass",
    table             => "cmdb_ci",
    certname_field    => "fqdn",
    classes_field     => "u_puppet_classes",
    environment_field => "u_puppet_environment",
  }
  HERE

  # This manifest will output the full contents of the $trusted variable.
  # Use it in conjunction with the capture_trusted_notice function to gain access
  # to the data available to manifests  in Puppet as a Ruby hash from the acceptance tests.
  TRUSTED_EXTERNAL_VARIABLE = <<-HERE.freeze
  $trusted_json = inline_template("<%= @trusted.to_json %>")
  notify { "trusted facts":
    message => $trusted_json
  }
  HERE

  def self.custom(instance: 'localhost:1080', user: 'user', password: 'password',
                  table: 'cmdb_ci', certname_field: 'fqdn', classes_field: 'u_puppet_classes',
                  environment_field: 'u_puppet_environment')

    # rubocop:disable  Lint/BlockAlignment
    params = method(__method__).parameters.map do |_, name|
               key   = name.to_s.ljust(17, ' ')
               value = binding.local_variable_get(name)
               "  #{key} => #{value},"
             end

    <<-HERE
    class {'servicenow_cmdb_integration::trusted_external_command':,
    #{params.join("\n")}
    }
    HERE
  end
end
