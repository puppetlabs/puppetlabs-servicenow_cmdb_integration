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
# @param [String] snowinstance The FQDN of the ServiceNow instance to query
# @param [String] user The username of the account with permission to query data
# @param [String] password The password of the account used to query data from Servicenow
# @param [String] table The table in Servicenow that will contain the required data
# @param [String] sys_id :shrug:
class servicenow_integration::trusted_external_command (
  String $snowinstance,
  String $user,
  Sensitive[String] $password,
  String $table
) {
  $resource_dependencies = flatten([
    file { '/etc/puppetlabs/puppet/get-servicenow-node-data.rb':
      ensure => file,
      owner  => 'pe-puppet',
      group  => 'pe-puppet',
      mode   => '0755',
      source => 'puppet:///modules/servicenow_integration/get-servicenow-node-data.rb',
    },

    file { '/etc/puppetlabs/puppet/servicenow.yaml':
      ensure  => file,
      owner   => 'pe-puppet',
      group   => 'pe-puppet',
      mode    => '0640',
      content => epp('servicenow_integration/servicenow.yaml.epp', {
        snowinstance => $snowinstance,
        user         => $user,
        password     => $password,
        table        => $table
      }),
    },
  ])

  pe_ini_setting { 'puppetserver puppetconf trusted external script':
    ensure  => present,
    path    => '/etc/puppetlabs/puppet/puppet.conf',
    setting => 'trusted_external_command',
    value   => '/etc/puppetlabs/puppet/get-servicenow-node-data.rb',
    section => 'master',
    require => $resource_dependencies,
  }
}
