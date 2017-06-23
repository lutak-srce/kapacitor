#
# = Class: kapacitor
#
# This class manages InfluxData Kapacitor service
#
#
# == Parameters
#
# [*ensure*]
#   Type: string, default: 'present'
#   Manages package installation and class resources. Possible values:
#   * 'present' - Install package, ensure files are present (default)
#   * 'absent'  - Stop service and remove package and managed files
#
# [*package*]
#   Type: string, default on $::osfamily basis
#   Manages the name of the package.
#
# [*version*]
#   Type: string, default: undef
#   If this value is set, the defined version of package is installed.
#   Possible values are:
#   * 'x.y.z' - Specific version
#   * latest  - Latest available
#
# [*status*]
#   Type: string, default: 'enabled'
#   Define the provided service status. Available values affect both the
#   ensure and the enable service arguments:
#   * 'enabled':     ensure => running, enable => true
#   * 'disabled':    ensure => stopped, enable => false
#   * 'running':     ensure => running, enable => undef
#   * 'stopped':     ensure => stopped, enable => undef
#   * 'activated':   ensure => undef  , enable => true
#   * 'deactivated': ensure => undef  , enable => false
#   * 'unmanaged':   ensure => undef  , enable => undef
#
# [*dependency_class*]
#   Type: string, default: vertica::dependency
#   Name of a class that contains resources needed by this module but provided
#   by external modules. Set to undef to not include any dependency class.
#
# [*my_class*]
#   Type: string, default: undef
#   Name of a custom class to autoload to manage module's customizations
#
# [*noops*]
#   Type: boolean, default: false
#   Set noop metaparameter to true for all the resources managed by the module.
#   If true no real change is done is done by the module on the system.
#
class kapacitor (
  $ensure                  = $::kapacitor::params::ensure,
  $package                 = $::kapacitor::params::package,
  $service                 = $::kapacitor::params::service,
  $version                 = $::kapacitor::params::version,
  $status                  = $::kapacitor::params::status,
  $urls                    = [ 'http://localhost:8086' ],
  $username                = '',
  $password                = '',
  $smtp_enabled            = false,
  $smtp_host               = 'localhost',
  $smtp_port               = 25,
  $smtp_username           = '',
  $smtp_password           = '',
  $smtp_from               = '',
  $file_mode               = $::kapacitor::params::file_mode,
  $file_owner              = $::kapacitor::params::file_owner,
  $file_group              = $::kapacitor::params::file_group,
  $template_kapacitor_conf = 'kapacitor/kapacitor.conf.erb',
  $dependency_class        = $::kapacitor::params::dependency_class,
  $my_class                = $::kapacitor::params::my_class,
  $noops                   = false,
  $manage_user             = $::kapacitor::params::manage_user,
  $manage_sys              = $::kapacitor::params::manage_sys,
) inherits kapacitor::params {

  ### Input parameters validation
  validate_re($ensure, ['present','absent'], 'Valid values are: present, absent')
  validate_string($package)
  validate_string($service)
  validate_string($version)
  validate_re($status,  ['enabled','disabled','running','stopped','activated','deactivated','unmanaged'], 'Valid values are: enabled, disabled, running, stopped, activated, deactivated and unmanaged')

  ### Internal variables (that map class parameters)
  if $ensure == 'present' {
    $package_ensure = $version ? {
      ''      => 'present',
      default => $version,
    }
    $service_enable = $status ? {
      'enabled'     => true,
      'disabled'    => false,
      'running'     => undef,
      'stopped'     => undef,
      'activated'   => true,
      'deactivated' => false,
      'unmanaged'   => undef,
    }
    $service_ensure = $status ? {
      'enabled'     => 'running',
      'disabled'    => 'stopped',
      'running'     => 'running',
      'stopped'     => 'stopped',
      'activated'   => undef,
      'deactivated' => undef,
      'unmanaged'   => undef,
    }
    $file_ensure = present
  } else {
    $package_ensure = 'absent'
    $service_enable = undef
    $service_ensure = stopped
    $file_ensure    = absent
  }

  ### Extra classes
  if $dependency_class { include $dependency_class }
  if $my_class         { include $my_class         }

  package { 'kapacitor':
    ensure  => $package_ensure,
    name    => $package,
    noop    => $noops,
  }
  service { $service:
    ensure  => $service_ensure,
    enable  => $service_enable,
    require => Package[$package],
    noop    => $noops,
    subscribe => File['/etc/kapacitor/kapacitor.conf'],
  }

  # set defaults for file resource in this scope.
  File {
    ensure  => $file_ensure,
    owner   => $file_owner,
    group   => $file_group,
    mode    => $file_mode,
    noop    => $noops,
  }
  file { '/etc/kapacitor/kapacitor.conf':
    require => Package['kapacitor'],
    content => template($template_kapacitor_conf),
  }
}
# vi:syntax=puppet:filetype=puppet:ts=4:et:nowrap:
