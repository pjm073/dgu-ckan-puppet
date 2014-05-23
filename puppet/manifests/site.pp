Exec {
  # Set defaults for execution of commands
  path => "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/opt/ruby/bin",
}
group {"ubuntu":
  ensure => present,
}
file {"/home/ubuntu":
  require => [ User["ubuntu"], Group["ubuntu"] ],
  ensure  => directory,
  owner   => "ubuntu",
  group   => "ubuntu",
}
user { "ubuntu":
  require    => Group["ubuntu"],
  ensure     => present,
  managehome => true,
  gid        => "ubuntu",
  shell      => "/bin/bash",
  home       => "/home/ubuntu",
  groups     => ["sudo","adm","www-data"],
}

file { '/etc/fqdn':
  content => $::fqdn
}
file { '/etc/motd':
  content => "Welcome to your Puppet-built virtual machine!
              $motd\n"
}
file { '/home/ubuntu/.bashrc':
   ensure => 'link',
   target => '/vagrant/.bashrc',
}
package { "screen":
  ensure => "installed"
}
package { "vim":
  ensure => "installed"
}
package { "pv":
  ensure => "installed"
}
package { "unzip":
  ensure => "installed"
}

include dgu_ckan

