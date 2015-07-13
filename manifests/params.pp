# - Class: transmission::params
#
# Default Parameter values

class transmission::params {
  $config_path        = '/opt/transmission'
  $download_dir       = '/downloads'
  $incomplete_dir     = undef
  $blocklist_url      = undef
  $web_port           = 9091
  $web_user           = 'transmission'
  $web_password       = undef
  $web_whitelist      = []
  $package_name       = 'transmission-daemon'
  $transmission_user  = 'transmission'
  $transmission_group = 'transmission'
  $service_name       = $package_name
  $umask              = 18 # Umask for downloaded files (in decimal)
  $ratio_limit        = undef # No ratio limit
  $peer_port          = 61500 #
  $speed_down         = undef # undef=Unlimited
  $speed_up           = undef # undef=Unlimited
  $seed_queue_enabled = true
  $seed_queue_size    = 10
  $upnp               = false
}
