RetirementPlan.io - Rails API
==================================

Services/Dependencies
----------------------

*Local*

- Ruby installed on dev machine/server
- Postgresql
- Redis
- Memcached
- Mandrill (via API key)

*Remote*

- Finance service `rp-finance.herokuapp.com`
- Simulation service `rp-simulation.herokuapp.com`
- Ember frontend (somewhere)

Development
-----------

### Initial Installation ###

For getting up and running on Mac OS X

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

- `bin/rails server`
