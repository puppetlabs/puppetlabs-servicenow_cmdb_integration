class Manifests
  DEFAULT = <<-HERE.freeze
  class {"servicenow_integration::trusted_external_command":
    instance => "localhost:1080",
    user     => "devuser",
    password => "devpass",
  }
  HERE

  ALL_PROPERTIES_DEFINED = <<-HERE.freeze
  class {"servicenow_integration::trusted_external_command":
    instance          => "localhost:1080",
    user              => "devuser",
    password          => "devpass",
    table             => "cmdb_ci",
    certname_field    => "fqdn",
    classes_field     => "u_puppet_classes",
    environment_field => "u_puppet_environment",
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
    class {'servicenow_integration::trusted_external_command':,
    #{params.join("\n")}
    }
    HERE
  end
end
