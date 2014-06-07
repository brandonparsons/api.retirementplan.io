#!/bin/bash

####################
# MEMCACHED CONFIG #
####################

# BASE plus....

if [ ! -f /var/.memcache-config ]; then

  ##############

  if [ -z "$1" ]; then
    echo "Argument not passed - executing fully."
    NOT_VAGRANT=1
  else
    echo "Argument passed - treating as vagrant."
    NOT_VAGRANT=0
  fi

  ##############

  export DEBIAN_FRONTEND=noninteractive

  echo Installing Memcached....

  apt-get -y install memcached

  ##############

  update-rc.d memcached disable
  update-rc.d -f memcached remove
  service memcached stop

  #### MULTILINE ###

  echo "
  start on runlevel [2345]
  stop on runlevel [!2345]

  respawn
  respawn limit 10 5

  exec /usr/bin/memcached -m MAXMEMORY -u memcache -l LISTENIP
  " >> /etc/init/memcached.conf

  #######

  ##############

  if [ ${NOT_VAGRANT} -eq 1 ]; then
    ufw allow from 10.0.90.0/24 to any port 11211
  fi

  if [ ${NOT_VAGRANT} -eq 1 ]; then
    sed -i "s|MAXMEMORY|500|g" /etc/init/memcached.conf
    sed -i "s|LISTENIP|internal-ip|g" /etc/init/memcached.conf
  else
    sed -i "s|MAXMEMORY|64|g" /etc/init/memcached.conf
    sed -i "s|LISTENIP|127\.0\.0\.1|g" /etc/init/memcached.conf
  fi

  ##############

  service memcached start

  ##############

  echo "
  /var/log/memcached.log {
    weekly
    missingok
    copytruncate
    rotate 12
    compress
    notifempty
  }
  " >> /etc/logrotate.d/memcached

  ##############


  touch /var/.memcache-config
fi
