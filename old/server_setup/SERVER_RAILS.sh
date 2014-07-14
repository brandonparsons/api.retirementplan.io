#!/bin/bash

#####################
# RUBY/RAILS CONFIG #
#####################

# BASE plus....

if [ ! -f /var/.rails-config ]; then

  ##############

  if [ -z "$1" ]; then
    echo "Argument not passed - NOT vagrant."
    NOT_VAGRANT=1
    echo "May not have SSH forwarding set up correctly - you need to check. Not in staging env."

    ENV_TO_SET=production
  else
    echo "Argument passed - treating as vagrant."
    NOT_VAGRANT=0

    SOCKET=$(ls -1 --sort t /tmp/ssh-*/agent.* | head -1)
    export SSH_AUTH_SOCK="${SOCKET}"
    mkdir -p ~/.ssh
    echo -e "Host github.com\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config
    echo -e "Host bitbucket.org\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config

    ENV_TO_SET=staging
  fi

  ##############

  export DEBIAN_FRONTEND=noninteractive

  echo Setting key environment variables..... rack/rails env to $ENV_TO_SET
  echo "\
RAILS_ENV=$ENV_TO_SET
RACK_ENV=$ENV_TO_SET
" >> /etc/environment
  echo "\
export RAILS_ENV=$ENV_TO_SET
export RACK_ENV=$ENV_TO_SET
" > /etc/profile.d/rails_env.sh
  chmod +x /etc/profile.d/rails_env.sh

  ##############

  # Deploy user for Capistrano - specific sudo abilities

  adduser --gecos "" deploy --disabled-password
  mkdir -p /home/deploy/.ssh && chmod 700 /home/deploy/.ssh
  echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDSsV7B+QyfnugxuYe49gHEvDU5teqjJAbfl7GAxiuaYoCCwQinHX4HYtzxrUzBq8ryAzub7MS0bxpCSn7Roal1s+3CbpuT9nmGgWQ9b24J0X4u3aC99lhBc51jmwabnIwnQGiyN9euf6zRRVjblB/qEWLBV/beASfYYbr3QxEGuYU5rW7lLJoFI+V1VNMhqTAPLFhB+e0+5ckJdy3mIygdEeJYApCaKD8c1bSK8WenlBL+SeOeHOJ4Q85E+kUWU7uArqzYbRcFnMcx9IDUyUN0ONYzY+wrGa8Pt/+zyg/lbMu+6f225Gw4n6CQf+fu0m2T7p6r9xiB3GDaZqvxGKq/ RP DEPLOY' >> /home/deploy/.ssh/authorized_keys
  chmod 400 /home/deploy/.ssh/authorized_keys
  chown deploy:deploy /home/deploy -R

  sed -i 's/AllowUsers brandon/AllowUsers brandon deploy/g' /etc/ssh/sshd_config
  service ssh restart


  echo 'deploy ALL=(ALL) NOPASSWD: /opt/apps/retirementplan.io/current/bin/foreman_export_upstart' >> /etc/sudoers.d/deploy
  echo 'deploy ALL=(ALL) NOPASSWD: /opt/apps/retirementplan.io/current/bin/puma_phased_restart' >> /etc/sudoers.d/deploy
  echo 'deploy ALL=(ALL) NOPASSWD: /usr/sbin/service retirementplan stop' >> /etc/sudoers.d/deploy
  echo 'deploy ALL=(ALL) NOPASSWD: /usr/sbin/service retirementplan start' >> /etc/sudoers.d/deploy
  echo 'deploy ALL=(ALL) NOPASSWD: /usr/sbin/service retirementplan restart' >> /etc/sudoers.d/deploy
  chmod 0440 /etc/sudoers.d/deploy

  # App user runs app - no sudo
  adduser --gecos "" appuser --disabled-password

  ##############

  ## Create app directory
  mkdir -p /opt/apps
  chown deploy:deploy /opt/apps

  ## Create log directory
  mkdir -p /var/log/retirementplan
  chown appuser:appuser /var/log/retirementplan

  ## Convenience
  echo "alias app='cd /opt/apps/retirementplan.io/current'" >>  /etc/bash.bashrc
  echo "alias c='cd /opt/apps/retirementplan.io/current && RAILS_ENV=production bundle exec rails console --sandbox'" >>  /etc/bash.bashrc
  echo "alias cc='cd /opt/apps/retirementplan.io/current && RAILS_ENV=production bundle exec rails console'" >>  /etc/bash.bashrc
  echo "alias t='cd /opt/apps/retirementplan.io/current && tail -n 100 -f log/sidekiq.log log/production.log'" >>  /etc/bash.bashrc

  ##############

  echo "Nginx setup for app server...."

  apt-get -y install nginx-extras

  mv /etc/nginx /etc/nginx.old
  mv /etc/init.d/nginx /etc/init.d/OLDnginx

  git clone git@bitbucket.org:retirementplanio/nginx-configuration-app-server.git /etc/nginx

  mkdir -p /var/log/nginx

  if [ ${NOT_VAGRANT} -eq 1 ]; then
    ufw allow proto tcp from 10.0.90.0/24 to any port 80
  else

    # Self-signed key for *.retirementplan.dev
    mkdir -p /etc/ssl
    echo "-----BEGIN CERTIFICATE-----
MIIDRDCCAiwCCQDXgZmUgfOxYTANBgkqhkiG9w0BAQUFADBkMQswCQYDVQQGEwJD
QTETMBEGA1UECBMKU29tZS1TdGF0ZTEhMB8GA1UEChMYSW50ZXJuZXQgV2lkZ2l0
cyBQdHkgTHRkMR0wGwYDVQQDFBQqLnJldGlyZW1lbnRwbGFuLmRldjAeFw0xNDAz
MjYxMjM4MzBaFw0xNTAzMjYxMjM4MzBaMGQxCzAJBgNVBAYTAkNBMRMwEQYDVQQI
EwpTb21lLVN0YXRlMSEwHwYDVQQKExhJbnRlcm5ldCBXaWRnaXRzIFB0eSBMdGQx
HTAbBgNVBAMUFCoucmV0aXJlbWVudHBsYW4uZGV2MIIBIjANBgkqhkiG9w0BAQEF
AAOCAQ8AMIIBCgKCAQEA8lqR735WHPi/fnBa8AxP9MeFMvo8qZF2NkYJ07DEKIGs
eDHdTWBmwRQvNhuRsji80suSy+FzjTysMWRlobtU7f+jxMLhBHAcVyhVvsyaf2YO
mjnP3E2lQ4IJ3XhwtCMOEMyOD2Dmu1rzTvYCDr+wFm8hz5+4dQFkaXWF0klGZXG9
JWQRjmQ8ILiwDX+iiRCCJvFCw7a5Z0dlzDs7sz6313sH8qtdikOOIrhSsIJNl9UX
0X/hnLyDM1h2KtuFibtfbdRnjfxmoLH8cZZtjntV93WZIuqq7P7GRiT8k5p8M/Jf
kwLOJd9+mKni4rlEuCgfThg7D1Isf7XMHhZFSh0WFQIDAQABMA0GCSqGSIb3DQEB
BQUAA4IBAQCrqrJaHTnFh0zHqX9lFgayUTRzevawrO2eKTE318+/xs1kQCl/HH6T
DIU72yGOxzwL91YdBiqErwuwOuB9JuX9fE2Ytz8mLlGBsSML49i0Oq31yIBRuATm
604/Jak/QIkJ3e3+3yLJrjw+vMgnU36E7uKdBRZCK+lK91lw11ytce/BDLEW/lWA
cva3OdDhVzhoCK9nlSdNPeY4T0u2nHVfwJdMPh4kRJdydBryUWNtjtEjJRKrbkOQ
YwgdKn9BwpYgunWxDiMxZS7X1gMpGneoL9Pz0YUrjQ+LOgu0wt3zWVhFZttgoDY0
hOMupeJ9T4MCdFxMhcPIX7cJFRs63nTM
-----END CERTIFICATE-----
" > /etc/ssl/ssl.crt

    echo "-----BEGIN RSA PRIVATE KEY-----
MIIEpQIBAAKCAQEA8lqR735WHPi/fnBa8AxP9MeFMvo8qZF2NkYJ07DEKIGseDHd
TWBmwRQvNhuRsji80suSy+FzjTysMWRlobtU7f+jxMLhBHAcVyhVvsyaf2YOmjnP
3E2lQ4IJ3XhwtCMOEMyOD2Dmu1rzTvYCDr+wFm8hz5+4dQFkaXWF0klGZXG9JWQR
jmQ8ILiwDX+iiRCCJvFCw7a5Z0dlzDs7sz6313sH8qtdikOOIrhSsIJNl9UX0X/h
nLyDM1h2KtuFibtfbdRnjfxmoLH8cZZtjntV93WZIuqq7P7GRiT8k5p8M/JfkwLO
Jd9+mKni4rlEuCgfThg7D1Isf7XMHhZFSh0WFQIDAQABAoIBAQCy6kYeZkgwbzr/
nvajjJNihAFDlxU9odOBUcdjbnYB6Wln+ngD7Y0uMTaBXWz8A4Lyo7MlrLTfqdD9
Tb7x3Rhf83/1fGEeI53ogjB7ARV1w+Q320Imw3OkGNYrmASsF80Efd7KX6E243gH
7Pmr5bubdEOjwagtSO/WIxq+GbZMoHFaqshx11gWJKczdHtX/OZleSz3Ul0lM1Ti
4TRszdRJG0y3QhAeA/YNS9IItDJ/42BpExSRGjS8EWtJBgjj8Xm/o06poyNJuQ0s
RCo0dnzDSTdcoh3/rGPwnkdPQ9VpVvpC0LYthDWbIRKhV3CpUpXDzDoXrii6ytDc
xwmXakbpAoGBAPnGS0g5jOLtuqNuXS0num5TopjuMSzSyjnZt1lAEoUlX1kEhJp+
JZhjRRzKj0aljczAED/IRsbc3+CAU5iiVxuIH6B3cln1UhbiCp64jyJeE4SZzdy+
pq9CyeZFDruQs0MOLIjfHR0Lmqa4psvU1p/ms2qy+AY6I4wzNQvyzVGnAoGBAPhk
7VGGMuh8/dSeZUAuBUn8AnerrqYeJ0tt0kW+tXUK8HyY4m8xDKLZUHCuU6YrYcz5
0ZiEMtLgf0FHg7w20lMGOG6tYe0xU084MQd666fGQ24VxvUNLTjyGDz6PXXABKU+
xqq1PO4x+75Q0Gqj0+DVnuFguKt1GXakOKd7FLnjAoGBAMCOmqMHmxGnbGdqQfL5
2cQMPiHgH5EKwFRw/+SSfLSg5yzdSs0/ywP8I9/aWTKBlxvuRZimccoFpaKRy+Cz
5quW+arf6wxnD+4MPVu3tMEt/aYQXKB9aktbFgOr4XvARjK/zp2GRA+MTqGRYSVq
5DtJw6/SYVuLnrQLFi4r9RWpAoGADon5yhfMywbl5JgQ3RzUemwhyNdntZl2O1gG
QsbS4DLvuJtKRa/dSXrm1nGdu9A2PUUyG3dBck5ppGyHLXEYBnwKuY+0d6m3cp+b
XxC20m8sazkjGBzZVMf22zradhXzL6jo//zzwA106sLYMCW+tR5L2m1K4d5My0D5
f/QYVnkCgYEAkMkSZJnujOWMFPh0fG1aVHLnxEYpR0rLUq4itrELdzVgOXYYI5VK
yz0BnpX2orMrLD235Nv4WtUQ5NlP7QXs/Ug5YcKvJEuv7ahXjHowTSudfu9M2F8W
lLY+L/DqlGirXO/NApWLgFY9PTbFiyRBPh2ctu4j4Tg//wiHNYSXN3c=
-----END RSA PRIVATE KEY-----
" > /etc/ssl/ssl.key


  # Listen to both HTTP & HTTPS on nginx in staging (normally SSL is terminated
  # on load balancer)
    sed -i -e 's|server_name _;|listen 443;\
      server_name app\.retirementplan\.stg;\
      ssl on;\
      ssl_certificate \/etc\/ssl\/ssl\.crt;\
      ssl_certificate_key \/etc\/ssl\/ssl.key;\
    |g' /etc/nginx/sites-available/app.retirementplan.io
  fi

  ##############

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

  echo "Installing R/RServe/R Packages...."

  # Install R #
  echo 'deb http://probability.ca/cran/bin/linux/ubuntu precise/' >> /etc/apt/sources.list
  apt-get -qq update && apt-get -y --force-yes install r-base

  # Install R packages, set up RServe #
  mkdir -p /src

  git clone git@bitbucket.org:retirementplanio/r-packages.git /src/r_packages
  cd /src/r_packages
  ./bin/install_packages.sh

  ##############

  echo "Installing Ruby...."

  ## Ruby dependencies ##
  apt-get -y install build-essential libreadline-dev libssl-dev libsqlite3-dev sqlite3 libyaml-dev libxml2-dev libxslt1-dev zlib1g-dev

  ## Postgres dependencies ##
  apt-get -y install libpq-dev

  ## Install Ruby ##
  git clone https://github.com/sstephenson/ruby-build.git && cd ruby-build && ./install.sh
  CONFIGURE_OPTS=--disable-install-rdoc
  ruby-build 2.0.0-p451 /usr/local
  gem update --system
  gem pristine --all
  gem install bundler --no-ri --no-rdoc

  ##############

  ## statsample gem has an optimization package, easily installed on linux (annoying on mac) ##
  ## Not sure if this will be picked up by statsample in a Bundler environment, but worth a shot for now. ##
  apt-get -y install build-essential libgsl0-dev
  gem install statsample-optimization --no-ri --no-rdoc

  ##############

  echo "Installing Node....."

  ## Install NodeJS (need a JS runtime) ##
  add-apt-repository ppa:chris-lea/node.js
  apt-get -qq update && apt-get -y install nodejs

  ##############

  #############
  #MULTILINE#

  # Rotate app logs
  echo "/var/log/retirementplan/*.log {
    daily
    missingok
    copytruncate
    rotate 7
    compress
  }" > /etc/logrotate.d/retirementplan_app

  #######

  ##############


  touch /var/.rails-config
fi
