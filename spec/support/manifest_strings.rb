class Manifests
  Default = <<~HERE
  class {'servicenow_integration::trusted_external_command':
    instance => 'localhost:1080',
    user     => 'devuser',
    password => 'devpass',
  }
  HERE

  AllPropertiesDefined = <<~HERE
  class {'servicenow_integration::trusted_external_command':
    instance          => 'localhost:1080',
    user              => 'devuser',
    password          => 'devpass',
    table             => 'fake_table',
    certname_field    => 'fqdn',
    classes_field     => 'u_puppet_classes',
    environment_field => 'u_puppet_environment',
  }
  HERE

  def self.custom(instance: 'localhost:1080', user: 'user', password: 'password',
                  table: 'cmdb_ci', certname_field: 'fqdn', classes_field: 'u_puppet_classes',
                  environment_field: 'u_puppet_environment')

    params =  method(__method__).parameters.map do |_, name|
                key   = name.to_s.ljust(17, ' ')
                value = binding.local_variable_get(name)
                "  #{key} => #{value},"
              end.join("\n")

    <<~HERE
    class {'servicenow_integration::trusted_external_command':,
    #{params}
    }
    HERE
  end
end