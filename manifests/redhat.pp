# Class: transmission::redhat
#
class transmission::redhat {
  if $::osfamily == 'RedHat' {
    file { '/etc/sysconfig/transmission-daemon':
      ensure  => file,
      content => "DAEMON_ARGS=\"-T --blocklist -g ${::transmission::config_path}\"",
      before  => Service['transmission-daemon'],
      notify  => Service['transmission-daemon'],
    }
  }
}
