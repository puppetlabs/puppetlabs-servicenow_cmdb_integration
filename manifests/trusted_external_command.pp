# @summary Configure ServiceNow integration on the Puppet Master
#
# Configure a Puppet Master to use the get-snow-node-data.rb script
# to query information from ServiceNow to use during catalog compilation.
# This class places required files in their directories and modifies
# Puppet.conf to ensure the trusted_external_command setting is pointed at
# the correct file. This class will need to be assigned to the master and
# the correct parameter values assigned.
#
# @example
#   include servicenow_integration::puppetserver
# @param [String] instance The FQDN of the ServiceNow instance to query
# @param [String] user The username of the account with permission to query data
# @param [String] password The password of the account used to query data from Servicenow
# @param [String] table The table in Servicenow that will contain the required data
# @param [String] sys_id :shrug:
class servicenow_integration::trusted_external_command (
  String $instance,
  String $user,
  String $password,
  String $certname_field    = 'fqdn',
  String $table             = 'cmdb_ci',
  String $classes_field     = 'u_puppet_classes',
  String $environment_field = 'u_puppet_environment'
) {
  # Warning: These values are parameterized here at the top of this file, but the
  # path to the yaml file is hard coded in the get-servicenow-node-data.rb script.
  $puppet_base = '/etc/puppetlabs/puppet'
  $external_commands_base = "${puppet_base}/trusted-external-commands"

  $resource_dependencies = flatten([

    file { $external_commands_base:
      ensure => directory,
      owner  => 'pe-puppet',
      group  => 'pe-puppet',
    },

    file { "${external_commands_base}/get-servicenow-node-data.rb":
      ensure  => file,
      owner   => 'pe-puppet',
      group   => 'pe-puppet',
      mode    => '0755',
      source  => 'puppet:///modules/servicenow_integration/get-servicenow-node-data.rb',
      require => [File[$external_commands_base]],
    },

    file { "${puppet_base}/servicenow.yaml":
      ensure  => file,
      owner   => 'pe-puppet',
      group   => 'pe-puppet',
      mode    => '0640',
      content => epp('servicenow_integration/servicenow.yaml.epp', {
        instance       => $instance,
        user           => $user,
        password       => $password,
        table          => $table,
        certname_field => $certname_field
      }),
    },
  ])

  pe_ini_setting { 'puppetserver puppetconf trusted external script':
    ensure  => present,
    path    => '/etc/puppetlabs/puppet/puppet.conf',
    setting => 'trusted_external_command',
    value   => "${external_commands_base}/get-servicenow-node-data.rb",
    section => 'master',
    require => $resource_dependencies,
  }
}
