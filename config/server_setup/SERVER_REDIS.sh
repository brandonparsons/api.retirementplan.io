#!/bin/bash

################
# REDIS CONFIG #
################

# BASE plus....

if [ ! -f /var/.redis-config ]; then

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

  echo Installing Redis...

  mkdir -p /src
  mkdir -p /etc/redis
  mkdir -p /var/redis
  mkdir -p /var/log/redis

  adduser --gecos "" redis --disabled-password
  chown redis:redis /var/redis
  chown redis:redis /var/log/redis

  cd /src
  wget http://download.redis.io/redis-stable.tar.gz
  tar xvzf redis-stable.tar.gz
  cd redis-stable
  make && make install

  ##############

  cp /src/redis-stable/redis.conf /etc/redis/redis.conf

  sed -i "s|daemonize yes|daemonize no|g" /etc/redis/redis.conf
  sed -i "s|dir \.\/|dir \/var\/redis|g"  /etc/redis/redis.conf

  if [ ${NOT_VAGRANT} -eq 1 ]; then
    sed -i "s|# bind 127\.0\.0\.1|bind internal-ip|g" /etc/redis/redis.conf
    sed -i "s|logfile \"\"|logfile \/var\/log\/redis\/redis.log|g" /etc/redis/redis.conf

    ## Don't limit maxmemory - not using as cache... should be watching this
    # sed -i "s|# maxmemory <bytes>|maxmemory 512mb|g"  /etc/redis/redis.conf
  fi

  ##############

  if [ ${NOT_VAGRANT} -eq 1 ]; then
    ufw allow from 10.0.90.0/24 to any port 6379
  fi

  ##############

  #### MULTILINE ###

  echo "
  start on runlevel [2345]
  stop on runlevel [!2345]

  respawn
  respawn limit 10 5

  exec start-stop-daemon --start --make-pidfile --pidfile /var/run/redis.pid --chuid redis --exec /usr/local/bin/redis-server /etc/redis/redis.conf
  " > /etc/init/redis.conf

  ###

  ##############

  service redis start

  ##############

  echo "
  /var/log/redis/*.log {
    weekly
    missingok
    copytruncate
    rotate 12
    compress
    notifempty
  }
  " >> /etc/logrotate.d/redis


  ###############


  touch /var/.redis-config
fi
