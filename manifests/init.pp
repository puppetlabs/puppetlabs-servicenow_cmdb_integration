# @summary Configures the servicenow.rb trusted external command
#
# @example
#   include servicenow_cmdb_integration
# @param [String] instance
#   The FQDN of the ServiceNow instance to query
# @param [String] user
#   The username of the account with permission to query data
# @param [String] password
#   The password of the account used to query data from Servicenow
# @param [String] oauth_token
#   An OAuth access token created in Servicenow that can be used in place of a
#   username and password.
# @param [String] table
#   The ServiceNow CMDB table to query. Defaults to 'cmdb_ci'. Note that you
#   should only set this if you'd like to query the information from a different
#   table.
# @param [String] certname_field
#   The column name of the CMDB field that contains the node's certname. Defaults
#   to 'fqdn'.
# @param [String] classes_field
#   The column name of the CMDB field that stores the node's classes. Defaults to
#   'u_puppet_classes'.
# @param [String] environment_field
#   The column name of the CMDB field that stores the node's environment. Defaults
#   to 'u_puppet_environment'.
# @param [String] snow_uri_erb
#   URI Template for the ServiceNow API, using field values from the config file. Defaults to 
#   'https://<%=instance%>/api/now/table/<%=table%>?#<%=certname_field%>=<%=certname%>&sysparm_display_value=true'.
# @param [String] debug
#   This enable the debugging more to allow for an indepth looks in to the Servicenow
#   Integration. i.e. ServiceNow API's URL, userid, but oauth_token and password are redacted.
class servicenow_cmdb_integration (
  String $instance,
  Optional[String] $user         = undef,
  Optional[String] $password     = undef,
  Optional[String] $oauth_token  = undef,
  String $table                  = 'cmdb_ci',
  String $certname_field         = 'fqdn',
  String $classes_field          = 'u_puppet_classes',
  String $environment_field      = 'u_puppet_environment',
  Optional[String] $snow_uri_erb = undef,
  Optional[String] $debug        = undef,
) {

  if (($user or $password) and $oauth_token) {
    fail('please specify either user/password or oauth_token not both.')
  }

  unless ($user or $password or $oauth_token) {
    fail('please specify either user/password or oauth_token')
  }

  if ($user or $password) {
    if $user == undef {
      fail('missing user')
    } elsif $password == undef {
      fail('missing password')
    }
  }

  # Warning: These values are parameterized here at the top of this file, but the
  # path to the yaml file is hard coded in the servicenow.rb script.
  $puppet_base = '/etc/puppetlabs/puppet'
  $external_commands_base = "${puppet_base}/trusted-external-commands"
  $validate_settings_path = '/tmp/validate_settings.rb'

  $resource_dependencies = flatten([

    file { $external_commands_base:
      ensure => directory,
      owner  => 'pe-puppet',
      group  => 'pe-puppet',
    },

    file { "${external_commands_base}/servicenow.rb":
      ensure  => file,
      owner   => 'pe-puppet',
      group   => 'pe-puppet',
      mode    => '0755',
      source  => 'puppet:///modules/servicenow_cmdb_integration/servicenow.rb',
      require => [File[$external_commands_base]],
    },

    file { $validate_settings_path:
      ensure  => file,
      owner   => 'pe-puppet',
      group   => 'pe-puppet',
      mode    => '0755',
      content => epp( 'servicenow_cmdb_integration/validate_settings.rb.epp', {
        require_path => "${external_commands_base}/servicenow.rb"
      }),
    },

    file { "${puppet_base}/servicenow_cmdb.yaml":
      ensure       => file,
      owner        => 'pe-puppet',
      group        => 'pe-puppet',
      mode         => '0640',
      validate_cmd => "${validate_settings_path} %",
      content      => epp('servicenow_cmdb_integration/servicenow_cmdb.yaml.epp', {
        instance          => $instance,
        user              => $user,
        password          => $password,
        oauth_token       => $oauth_token,
        table             => $table,
        certname_field    => $certname_field,
        classes_field     => $classes_field,
        environment_field => $environment_field,
        snow_uri_erb      => $snow_uri_erb,
        debug             => $debug,
      }),
    },
  ])

  ini_setting { 'puppetserver puppetconf trusted external command':
    ensure  => present,
    path    => '/etc/puppetlabs/puppet/puppet.conf',
    setting => 'trusted_external_command',
    value   => "${external_commands_base}/servicenow.rb",
    section => 'master',
    notify  => Service['pe-puppetserver'],
    require => $resource_dependencies,
  }
}
