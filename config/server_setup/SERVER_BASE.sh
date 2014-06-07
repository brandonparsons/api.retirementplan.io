#!/bin/bash

######################
# BASE SERVER CONFIG #
######################

if [ ! -f /var/.base-config ]; then

  ##############

  if [ -z "$1" ]; then
    echo "Argument not passed - NOT vagrant."
    NOT_VAGRANT=1
  else
    echo "Argument passed - executing for vagrant."
    NOT_VAGRANT=0
  fi

  ##############

  export DEBIAN_FRONTEND=noninteractive

  if [ ${NOT_VAGRANT} -eq 1 ]; then
    passwd # Change password for root
  fi

  ##############

  echo Installing base packages....

  ## Doesnt work properly on openstack image
  # sed 's/main$/main universe/' -i /etc/apt/sources.list
  apt-get -qq update

  if [ ${NOT_VAGRANT} -eq 1 ]; then
    DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade
  fi

  apt-get -y install \
    build-essential \
    make \
    gcc \
    tar \
    libssl-dev \
    zlib1g-dev \
    openssl \
    vim \
    curl \
    wget \
    nano \
    htop \
    fail2ban \
    git \
    unzip \
    iftop \
    python-software-properties \
    dnsutils


  echo Setting up locales....

  locale-gen en_US.UTF-8 && dpkg-reconfigure locales
  echo '
export LANGUAGE="en_US.UTF-8"
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
  ' > /etc/default/locale

  ##############

  if [ ${NOT_VAGRANT} -eq 1 ]; then
    ### **** ###
    # NEED TO CONFIRM IF THESE ARE CORRECT
    # Don't edit names unless find everywhere else. Including NGINX config on bitbucket
    OWN_IP=$(ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{print $1}')
    echo "$OWN_IP internal-ip"        >> /etc/hosts
    echo '10.0.90.3 frontend-server'  >> /etc/hosts
    echo '10.0.90.5 app-server-one'   >> /etc/hosts
    echo '10.0.90.4 database-server'  >> /etc/hosts
    #
    ### **** ###
  fi

  ##############

  if [ ${NOT_VAGRANT} -eq 1 ]; then
    # Remove authorized_keys from root
    rm ~/.ssh/authorized_keys
  fi

  if [ ${NOT_VAGRANT} -eq 1 ]; then
    adduser --gecos "" brandon # Has a password prompt
  else
    adduser --gecos "" --disabled-password brandon
    echo brandon:asdf | chpasswd
  fi

  mkdir -p /home/brandon/.ssh && chmod 700 /home/brandon/.ssh
  echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC3y0VdFCfIXAx/fmQxOslHBBYvbJpdBO4yxUisly618PuTzislSZyU+YI2jL1GdqVQFcjJRwLOru49VRscy+nqiuOCF2pTx/MPc0JJ25jh5gPJiYfods/fBgpIeJwPq5uPxnoTkrR4TWozjcuHAPwlzvzRvp2ohIrbN0JrQ09TnLeCu2LnnH2xYkr/mHJfNeWhUFxOAl4gmQmb3bQJnoiU+R4oRMEJoGdijCC7jNmVaIgR4nljrxyH3HYSZguvyGtxaR0+LA3LCHZVDQvzhDPyIVI3FK5IvtTWpy43e7pbhdIztM0g0d9ZLPwkeuJsQhS3rb3qKHxhWDtbyqegdhOz RP DAIR' >> /home/brandon/.ssh/authorized_keys
  chmod 400 /home/brandon/.ssh/authorized_keys
  chown brandon:brandon /home/brandon -R

  echo 'brandon ALL=(ALL) ALL' >> /etc/sudoers.d/brandon
  chmod 0440 /etc/sudoers.d/brandon

  ##############

  if [ ${NOT_VAGRANT} -eq 1 ]; then
    sed -i 's/Port 22/Port 2222/g'                                      /etc/ssh/sshd_config
    sed -i 's/PermitRootLogin yes/PermitRootLogin no/g'                 /etc/ssh/sshd_config
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g'  /etc/ssh/sshd_config

    echo 'AllowUsers brandon' >> /etc/ssh/sshd_config # AllowUsers deploy@(your-ip) deploy@(another-ip-if-any)
    service ssh restart

    sed -i 's/port     = ssh/port = 2222/g' /etc/fail2ban/jail.conf
    service fail2ban restart

    ufw default deny incoming
    ufw allow 2222 # Need to run migrations on database, and deploy code to app servers
    ufw limit 2222
    ufw enable

    apt-get -y install unattended-upgrades

    ##############
    #MULTILINE#
    # Purposefully overwriting existing content

    echo 'APT::Periodic::Update-Package-Lists "1";
    APT::Periodic::Download-Upgradeable-Packages "1";
    APT::Periodic::AutocleanInterval "7";
    APT::Periodic::Unattended-Upgrade "1";' > /etc/apt/apt.conf.d/10periodic

    ###############

    sed -i 's/"\${distro_id}:\${distro_codename}-security";/"Ubuntu precise-security";/g' /etc/apt/apt.conf.d/50unattended-upgrades


    apt-get -y install logwatch
    sed -i 's/--output mail/--output mail --mailto parsons.brandon@gmail.com --format html/g' /etc/cron.daily/00logwatch


    # New relic
    echo deb http://apt.newrelic.com/debian/ newrelic non-free >> /etc/apt/sources.list.d/newrelic.list
    wget -O- https://download.newrelic.com/548C16BF.gpg | apt-key add -
    apt-get -qq update && apt-get -y install newrelic-sysmond
    nrsysmond-config --set license_key= #####<< new relic key >> # (see .env.production)

    /etc/init.d/newrelic-sysmond start
  fi

  ##############


  touch /var/.base-config
fi
