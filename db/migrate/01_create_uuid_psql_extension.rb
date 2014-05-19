class CreateUuidPsqlExtension < ActiveRecord::Migration

  # This will work in development where the dev user has superuser role.
  # Will NOT work on production (not granting superuser to `deploy` user).
  # Therefore, need to ensure that template1 database has this extension added
  # when setting up the database server.

  def self.up
    execute "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";"
  end

  def self.down
    execute "DROP EXTENSION \"uuid-ossp\";"
  end
end
