# = Class: transmission
#
# This class installs/configures/manages the transmission-daemon bittorrent
# client.
#
# == Parameters:
#
# $download_dir:: The directory where the files have to be downloaded. Defaults
#   to +$config_path/downloads+.
# $incomplete_dir:: The temporary directory used to store incomplete files.
#   Disabled when the option is not set (this is the default).
# $web_port:: The port the web server is listening on. Defaults to +9091+.
# $web_user:: The web client login name. Defaults to +transmission+.
# $web_password:: The password of the web client user (default: <none>)
# $web_whitelist:: An array of IP addresses. This list define which machines
#   are allowed to use the web interface. It is possible to use wildcards in the
#   addresses. By default the list is empty.
# $blocklist_url:: An url to a block list (default: <none>)
# $package_name:: name of the package. Default to 'transmission-daemon'
# $transmission_user:: default 'transmission'
# $transmission_group:: default 'transmission'
# $service_name:: default = $package_name
#
# == Requires:
#
# Nothing.
#
# == Sample Usage:
#
#  class {'transmission':
#    download_dir   => "/downloads",
#    incomplete_dir => "/tmp/downloads",
#    web_port       => 9091,
#    web_whitelist  => ['127.0.0.1'],
#    blocklist_url  => 'http://list.iblocklist.com/?list=bt_level1',
#  }
#

class transmission (
  $config_path        = $transmission::params::config_path,
  $download_dir       = $transmission::params::download_dir,
  $incomplete_dir     = $transmission::params::incomplete_dir,
  $blocklist_url      = $transmission::params::blocklist_url,
  $web_port           = $transmission::params::web_port,
  $web_user           = $transmission::params::web_user,
  $web_password       = $transmission::params::web_password,
  $web_whitelist      = $transmission::params::web_whitelist,
  $package_name       = $transmission::params::package_name,
  $transmission_user  = $transmission::params::transmission_user,
  $transmission_group = $transmission::params::transmission_group,
  $service_name       = $transmission::params::service_name,
  $umask              = $transmission::params::umask,
  $ratio_limit        = $transmission::params::ratio_limit,
  $peer_port          = $transmission::params::peer_port,
  $speed_down         = $transmission::params::speed_down,
  $speed_up           = $transmission::params::speed_up,
  $seed_queue_enabled = $transmission::params::seed_queue_enabled,
  $seed_queue_size    = $transmission::params::seed_queue_size,
  $upnp               = $transmission::params::upnp,
) inherits transmission::params {

  $_settings_json = "${config_path}/settings.json"

  $settings_tmp = '/tmp/transmission-settings.tmp'

  package { 'transmission-daemon':
    ensure => installed,
    name   => $package_name,
  }

  # Find out the name of the transmission user/group
  # ## // Moved to calling class //

  # Transmission should be able to read the config dir
  file { $config_path:
    ensure   => directory,
    # We only set the group (the dir could be owned by root or someone else)
    group    => $transmission_group,
    # Make sure transmission can access the config dir
    mode     => 'g+rx',
    # Make sure that the package is installed and had the opportunity to create
    # the directory first
    require  => Package['transmission-daemon'],
  }

  # The settings file should follow our template
  file { 'settings.json':
    ensure  => file,
    path    => $_settings_json,
    content => template("${module_name}/settings.json.erb"),
    mode    => 'u+rw',          # Make sure transmisson can r/w settings
    owner   => $transmission_user,
    group   => $transmission_group,
    require => [Package['transmission-daemon'],File[$config_path]],
    notify  => Exec['activate-new-settings'],
  }

  # Helper. To circumvent transmission's bad habit of rewriting 'settings.json'
  # every now and then.
  exec { 'activate-new-settings':
    refreshonly => true,        # Run only when another resource
                                # (File['settings.json']) tells us to do it
    command     => "cp ${_settings_json} ${settings_tmp}; service ${service_name} stop; sleep 5; cat ${settings_tmp} > ${_settings_json}; chmod u+r ${_settings_json}",
    path        => ['/bin','/sbin', '/usr/sbin'],
    # Now we can tell the service about the changes // Start service
    notify      => Service['transmission-daemon'],
  }


  # Transmission should use the settings in ${config_path}/settings.json *only*
  # This is ugly, but necessary
  file {['/etc/default/transmission','/etc/sysconfig/transmission']:
    # Kill the bastards
    ensure  => absent,
    # The package has to be installed first. Otherwise this would be sheer
    # folly.
    require => Package['transmission-daemon'],
    # After this is fixed, we can handle the service
    before  => Service['transmission-daemon'],
  }

  # Manage the download directory.  Creating parents will be taken care of
  # "upstream" (in the calling class)
  file { $download_dir:
    ensure  => directory,
    # Broken. Creates invalid resurce tags for some downloaded files with funny
    # characters.
    #recurse => true,
    owner   => $transmission_user,
    group   => $transmission_group,
    mode    => 'ug+rw,u+x',
    # Let's give the installer a chance to create the directory and user before
    # we manage this dir
    require => Package['transmission-daemon'],
  }

  # directory for partial downloads
  if $incomplete_dir {
    file { $incomplete_dir:
      ensure  => directory,
      recurse => true,
      owner   => $transmission_user,
      group   => $transmission_group,
      mode    => 'ug+rw,u+x',
      require => Package['transmission-daemon'],
    }
  }

  # Keep the service running
  service { 'transmission-daemon':
    ensure     => running,
    name       => $service_name,
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
    require    => Package['transmission-daemon'],
  }

  # Keep blocklist updated
  if $blocklist_url {
    if $web_password {
      $opt_auth = " --auth ${web_user}:${web_password}"
    }
    else
    {
      $opt_auth = ''
    }
    cron { 'update-blocklist':
      command => "/usr/bin/transmission-remote ${web_port} ${opt_auth} --blocklist-update 2>&1 > /tmp/blocklist.log",
      user    => root,
      hour    => 2,
      minute  => 0,
      require => Package['transmission-daemon'],
    }
  }
}
