= Class: transmission

This class installs/configures/manages the transmission-daemon bittorrent client.

== Parameters: 

$download_dir:: The directory where the files have to be downloaded. Defaults to +$config_path/downloads+.
$incomplete_dir:: The temporary directory used to store incomplete files. Disabled when the option is not set (this is the default).
$web_path:: URL path for the web client (without trailing /). Disabled when the option is not set (this is the default).
$web_port:: The port the web server is listening on. Defaults to +9091+.
$web_user:: The web client login name. Defaults to +transmission+.
$web_password:: The password of the web client user (default: <none>)
$web_whitelist:: An array of IP addresses. This list define which machines are allowed to use the web interface. It is possible to use wildcards in the addresses. By default the list is empty.
$blocklist_url:: An url to a block list (default: <none>)

== Requires: 

Nothing.

== Sample Usage:

 class {'transmission':
   download_dir => "/downloads",
   incomplete_dir => "/tmp/downloads",
   web_path => "/bittorrent", ### Corrected
   web_port => 9091,
   web_whitelist => ['127.0.0.1'],
   blocklist_url => 'http://list.iblocklist.com/?list=bt_level1',
 }

