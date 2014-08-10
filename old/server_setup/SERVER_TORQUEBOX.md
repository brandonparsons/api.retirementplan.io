Server Setup - TORQUEBOX
--------------------------

- Guide assumes execution as `root`
- BASE plus....


```
apt-get -y purge openjdk*
apt-get -y install nodejs openjdk-7-jre-headless
```


```
ufw allow from 10.0.90.0/24 to any port 8080
```

```
# Install R, R packages, and RServe #

echo 'deb http://probability.ca/cran/bin/linux/ubuntu precise/' >> /etc/apt/sources.list

apt-get update && apt-get -y --force-yes install r-base

# Install R packages
mkdir /src

git clone https://brandonparsons@bitbucket.org/easyretirementplanning/r-packages.git /src/r_packages

cd /src/r_packages

R CMD INSTALL MASS_7.3-29.tar.gz
R CMD INSTALL robustbase_0.9-10.tar.gz
R CMD INSTALL timeDate_3010.98.tar.gz
R CMD INSTALL timeSeries_3010.97.tar.gz
R CMD INSTALL stabledist_0.6-6.tar.gz
R CMD INSTALL gss_2.1-0.tar.gz
R CMD INSTALL fBasics_3010.86.tar.gz
R CMD INSTALL mnormt_1.4-7.tar.gz
R CMD INSTALL numDeriv_2012.9-1.tar.gz
R CMD INSTALL sn_1.0-0.tar.gz
R CMD INSTALL fCopulae_3000.79.tar.gz
R CMD INSTALL fAssets_3002.80.tar.gz
R CMD INSTALL quadprog_1.5-5.tar.gz
R CMD INSTALL slam_0.1-31.tar.gz
R CMD INSTALL Rglpk_0.5-2.tar.gz
R CMD INSTALL fPortfolio_2130.80.tar.gz
R CMD INSTALL Rserve_1.8-0.tar.gz
R CMD INSTALL Cairo_1.5-5.tar.gz
R CMD INSTALL FastRWeb_1.1-0.tar.gz
R CMD INSTALL jsonlite_0.9.4.tar.gz
```

```
git clone git@bitbucket.org:easyretirementplanning/fastrweb-rserve-fportfolio.git /var/FastRWeb
```

```
##############
#MULTILINE#

echo 'description "FastRWeb/RServe Binary R Server"

start on runlevel [2345]
stop on runlevel [016]

respawn

setuid nobody

exec /var/FastRWeb/code/start' >> /etc/init/rserve.conf

################

# run it...

service rserve start
```

```
wget http://torquebox.org/release/org/torquebox/torquebox-dist/3.0.2/torquebox-dist-3.0.2-bin.zip
unzip torquebox-dist-3.0.2-bin.zip
mv torquebox-3.0.2/ /opt/torquebox
rm torquebox-dist-3.0.2-bin.zip

chown torquebox.torquebox -R /opt/torquebox/
```

```
##############
#MULTILINE#

echo 'export TORQUEBOX_HOME=/opt/torquebox
export JBOSS_HOME=$TORQUEBOX_HOME/jboss
export JRUBY_HOME=$TORQUEBOX_HOME/jruby
export PATH=$JRUBY_HOME/bin:$PATH' >> /etc/profile.d/torquebox.sh


###########

source /etc/profile.d/torquebox.sh

## jruby -S irb # Tests if installed correctly

echo 'export JAVA_OPTS="-Xms750m -Xmx1536m -XX:MaxPermSize=256m -XX:ReservedCodeCacheSize=100m"' >> /etc/profile.d/java_opts.sh

source /etc/profile.d/java_opts.sh
```

```
# cd /opt/torquebox
# rake torquebox:upstart:install
# sed -i 's/start on started network-services/start on runlevel \[2345\]/g' /etc/init/torquebox.conf
# sed -i 's/stop on stopped network-services/stop on runlevel \[016\]/g' /etc/init/torquebox.conf

OWN_IP=$(ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{print $1}')

##############
#MULTILINE#

echo "description 'This is an upstart job file for TorqueBox'

pre-start script
bash << 'EOF'
  mkdir -p /var/log/torquebox
  chown -R torquebox /var/log/torquebox
EOF
end script

start on (runlevel [2345] and net-device-up)
stop on runlevel [016]
respawn

limit nofile 4096 4096

script
bash << 'EOF'
  su - torquebox
  # /opt/torquebox/jboss/bin/standalone.sh >> /var/log/torquebox/torquebox.log 2>&1
  /opt/torquebox/jruby/bin/torquebox run --bind-address=$OWN_IP>> /var/log/torquebox/torquebox.log 2>&1  # --clustered
EOF
end script" > /etc/init/torquebox.conf

###################

service torquebox start
```

```
##############
#MULTILINE#

echo "/var/log/torquebox/*.log /opt/torquebox/jboss/standalone/log/*.log {
  daily
  rotate 14
  copytruncate
  notifempty
  missingok
  compress
  delaycompress
}" > /etc/logrotate.d/torquebox

########
```


```
##############
#MULTILINE#

# Newrelic has trouble finding the config file on redeploys. Setting env vars was a recommendation from New Relic support

echo "export NRCONFIG=/home/torquebox/apps/app.easyretirementplanning.ca/current/config/newrelic.yml
export NEW_RELIC_LOG=/home/torquebox/apps/app.easyretirementplanning.ca/current/log/newrelic_agent.log" > /etc/profile.d/newrelic.sh
########
```
