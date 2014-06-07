#!/bin/bash

###############################
# LOAD BALANCER SERVER CONFIG #
###############################

# BASE plus....

if [ ! -f /var/.lb-config ]; then

  ##############

  if [ -z "$1" ]; then
    echo "Argument not passed - NOT vagrant."
    NOT_VAGRANT=1
    echo "May not have SSH forwarding set up correctly - you need to check. Not in staging env."
  else
    echo "Argument passed - treating as vagrant."
    NOT_VAGRANT=0

    SOCKET=$(ls -1 --sort t /tmp/ssh-*/agent.* | head -1)
    export SSH_AUTH_SOCK="${SOCKET}"
    echo -e "Host github.com\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config
    echo -e "Host bitbucket.org\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config
  fi

  ##############

  export DEBIAN_FRONTEND=noninteractive

  echo Setting up load balancer....

  if [ ${NOT_VAGRANT} -eq 1 ]; then

    apt-get -y install nginx-extras

    mv /etc/nginx /etc/nginx.old
    mv /etc/init.d/nginx /etc/init.d/OLDnginx

    ufw allow 80
    ufw allow 443

    git clone git@bitbucket.org:retirementplanio/nginx-configuration-load-balancer.git /etc/nginx

    ## Nginx config has proxy_binding to ensure calls come from local IP (public IP closed). ##
    OWN_IP=$(ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{print $1}') # Already have this in hosts, but nginx wont resovle it for some reason
    sed -i "s|REPLACEMEWITHIP|$OWN_IP|g" /etc/nginx/sites-available/app.retirementplan.io

    mkdir -p /var/log/nginx

    echo "Need to copy in SSL certs!  /etc/ssl/ssl.crt , /etc/ssl/ssl.key"

    ##############

    mkdir -p /var/www/public
    chown brandon:brandon /var/www/public


    ##############
    #MULTILINE#

    echo 'description "Nginx HTTP Server"

    start on runlevel [2345]
    stop on runlevel [016]

    console owner

    exec /usr/sbin/nginx -c /etc/nginx/nginx.conf -g "daemon off;"

    respawn' >> /etc/init/nginx.conf

    ###########

    service nginx start


    ##############
    #MULTILINE#

    echo "/var/log/nginx/*.log {
      daily
      missingok
      rotate 14
      compress
      delaycompress
      notifempty
      create 640 nginx adm
      sharedscripts
      postrotate
        [ -f /var/run/nginx.pid ] && kill -USR1 'cat /var/run/nginx.pid'
      endscript
    }" > /etc/logrotate.d/nginx

    ####

    ##############

  fi

  ##############


  touch /var/.lb-config
fi
