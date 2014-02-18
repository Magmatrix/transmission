# = Class: transmission_daemon
# 
# This class installs/configures/manages the transmission-daemon bittorrent client. It can configure an RPC bittorrent client (web).
# 
# == Parameters: 
#
# $download_dir:: The directory where the files have to be downloaded. Defaults to +/var/lib/transmission-daemon/downloads+.
# $incomplete_dir:: The temporary directory used to store incomplete files. The feature is disabled when the option is not set. By default this feature is disabled.
# $rpc_url:: The access path to the RPC server (web). The feature is disabled when the option is not set. This path should not finish with the / (slash) char. By default this feature is disabled.
# $rpc_port:: The port the RPC server is listening on. Defaults to +9091+.
# $rpc_user:: The RPC user (ACL). Defaults to +transmission+.
# $rpc_password:: The password of the RPC user (ACL). By default this option is not set.
# $rpc_whitelist:: An array of IP addresses. This list define which machines are allowed to use the RPC interface. It is possible to use wildcards in the addresses. By default the list is empty.
# $blocklist_url:: An url to a block list. By default this option is not set.
#
# == Requires: 
# 
# Nothing.
# 
# == Sample Usage:
#
#  class {'transmission':
#    download_dir => "/downloads",
#    incomplete_dir => "/tmp/downloads",
#    rpc_url => "bittorrent/",
#    rpc_port => 9091,
#    rpc_whitelist => ['127.0.0.1'],
#    blocklist_url => 'http://list.iblocklist.com/?list=bt_level1',
#  }
#

class transmission (
  $download_dir = '/downloads', ## TODO: extlookup('transmission:download_dir'),  ### NOT WORKING!!??!!
  $incomplete_dir = undef,
  $rpc_url = undef,
  $rpc_port = 9091,
  $rpc_user = 'transmission',
  $rpc_password = undef,
  $rpc_whitelist = undef,
  $blocklist_url = undef,
  $config_path = undef,
) {

  package { 'transmission-daemon':
    ensure => installed,
  }

  exec { 'stop-daemon':
    command => 'service transmission-daemon stop',
    path    => ['/sbin', '/usr/sbin'],
    require => Package['transmission-daemon'], # Needs to be installed before we can try to stop it
  }

  # Fix the settings // TEST, not complete
  $input="${config_path}/settings.json"
  $output="/tmp/transmission-modified-settings"
  $my_download_dir="/TEST/MODIFIED/${download_dir}"
  exec { 'Modify settings.json .....':
    command => "sed 's|\"download-dir\":.*|\"download-dir\": \"${my_download_dir}\",|' ${input} > ${output}", # mv --force $outout $input
    path    => ['/bin'],
    require => File['settings.json'],
  }

  file { 'settings.json':
    path => "${config_path}/settings.json",
    ensure => file,
    require => Exec['stop-daemon'],
    content => template("${module_name}/settings.json.erb"),
    mode    => 'u+rw',          # Make sure transmisson can r/w settings
  }


  # Create DL directory ...
  # Big mess and a gazillion "Error 400" messages....
  file { "${download_dir}":
    ensure  => directory,
    # recurse => true, ## Doesn't do what it sounds like (does NOT create parent diectories)
    mode    => "ug+rw,u+x" # TODO: Should also check user and group (depends on distro)...
    ## require => Package['transmission-daemon'], # TODO: Make sure it's installed before creating DL-dir, then check owner, make sure DL-dir has same owner/group
  }
  $parts=split($download_dir,"/")
  $dir=""
  ## $parts.each {|$part|  ## XXXXX: Documentation on puppetlabs is wrong!! ? WTF??!
  each($parts) |$part| {
    $dir="$dir/$part"           # XXXXX: THIS IS BROKEN! VALUE DOES NOT CHANGE! WTF!!??
    if ($dir != '/') {
      file { "$dir":
        ensure => directory,
        before => Notify["$dir"]
      }
      notify { "$dir":
        message => "OK, '$dir' exists!"
      }
    }
  }

  
  if $incomplete_dir {
    file { "${incomplete_dir}":
      ensure  => directory,
      recurse => true,
      mode    => "ug+rw,u+x" # TODO: Should also check user and group (depends on distro)...
    }
  }


  service { 'transmission-daemon':
    name => 'transmission-daemon',
    ensure => running,
    enable => true,
    hasrestart => true,
    hasstatus => true,
    subscribe => File['settings.json'],
  }

  if $rpc_url and $blocklist_url {
    if $rpc_password {
      $opt_auth = " --auth ${rpc_user}:${rpc_password}"
    }
    else
    {
      $opt_auth = ""
    }
    cron { 'update-blocklist':
      command => "/usr/bin/transmission-remote http://127.0.0.1:${rpc_port}${rpc_url}${opt_auth} --blocklist-update 2>&1 > /tmp/blocklist-update.log",
      user => root,
      hour => 2,
      minute => 0,
      require => Package['transmission-daemon'],
    }
  }
}
 
