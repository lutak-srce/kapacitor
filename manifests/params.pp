# Class: kapacitor::params
#
# This module contains defaults for kapacitor modules
#
class kapacitor::params {

  $ensure           = 'present'
  $version          = undef
  $status           = 'enabled'
  $file_mode        = '0644'
  $file_owner       = 'kapacitor'
  $file_group       = 'kapacitor'
  $autorestart      = true
  $dependency_class = '::kapacitor::dependency'
  $my_class         = undef

  # install package depending on major version
  case $::osfamily {
    default: {}
    /(RedHat|redhat|amazon)/: {
      $package           = 'kapacitor'
      $service           = 'kapacitor'
    }
    /(debian|ubuntu)/: {
    }
  }

}
