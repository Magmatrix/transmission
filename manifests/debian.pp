# Class: transmission::debian
#
class transmission::debian {
  if $::osfamily == 'Debian' {
    file { '/etc/default/transmission-daemon':
      ensure  => file,
      content => 'ENABLE_DAEMON=0',
      before  => Service['transmission-daemon'],
    }
  }
}
