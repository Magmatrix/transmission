class transmission::redhat {
  if $osfamily == 'RedHat' { #check for sanity
    file { '/etc/sysconfig/transmission-daemon':
      ensure  => file,
      content => 'DAEMON_ARGS="-e /var/log/transmission-daemon.log"',
      before  => Service['transmission-daemon'],
    }
  }
}
