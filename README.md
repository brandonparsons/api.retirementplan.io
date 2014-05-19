RetirementPlan.io - Rails API
==================================

Services/Dependencies
----------------------

- R/Rserve
  + Set up as system service in production
  + Needs to be installed in local dev environment (e.g. on Mac). See development section below
- Ruby installed on dev machine/server
- Postgresql
- Redis
- Sidekiq
- Memcached
- Mandrill (via API key)
- Errbit (airbrake)


Browser Support
---------------

- ** Does NOT ** support IE<=8.0
  + NVD3 did not support 8.0, so you've gone with the modern builds of JQuery and Lodash.
- Supports >= IE 9.0 (probably), haven't tested
- Supports modern Chrome/Safari
- Supports modern opera (probably)


Misc Notes
------------

- Inflation and real estate return/std_dev data (from the models) is quoted monthly. RE was quarterly, converted to monthly (if changing data make sure to pull monthly or change the calculations in RealEstate!).  Security returns are saved as weekly.  Security returns converted to monthly during asset performance generation.
- Some NVD3 vendor javascript files have had patches manually applied, and/or custom code added. Have put notes at the top of the files to show where.\
- To update the flat YAML files (`db/data`) containing source data (from Google Drive): `rake google_docs`. This isn't necessary if files in version control are recent enough.


Production Server Setup
------------------------

See the `misc/server_config` folder and docker container build scripts for additional docs regarding server setup.


Development
-----------

### Initial Installation ###

For getting up and running on Mac OS X

- R 3.0.2
  + Install from `http://www.r-project.org/` **NOT** `brew` (messes up compilation toolchain)
    * `http://cran.stat.sfu.ca/bin/macosx/R-3.0.2.pkg`
  + Install gFortran compiler toolchain - again **NOT** from Homebrew, but from CRAN
    * `http://cran.stat.sfu.ca/bin/macosx/tools/gfortran-4.2.3.pkg`
- R packages:
  + `git clone https://brandonparsons@bitbucket.org/retirementplanio/r-packages.git /~somewhere~`
  + `cd /~somewhere~ && ./bin/install_packages.sh`

- Postgresql (9.3 preferably)
  + `brew install postgresql` 
  + Need to make sure have the right version... definitely >= 9.2 (haven't tested on 9.2)

- Redis
    + `brew install redis`

- `bundle install`
- `bundle exec rake db:create`
- `bundle exec rake db:migrate`
- `bundle exec rake db:seed`
- `RAILS_ENV=test bundle exec rake db:create && RAILS_ENV=test bundle exec rake db:mgirate`

### To Launch ###

`foreman start --procfile development_procfile`
