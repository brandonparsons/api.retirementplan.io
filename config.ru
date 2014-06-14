# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment',  __FILE__)

if Rails.env.profile?
  require 'fileutils'
  FileUtils.mkdir_p 'tmp/profile'
  use Rack::RubyProf, path: 'tmp/profile'
  at_exit do
    FileUtils.rm_rf 'tmp/profile'
  end
end

run Rails.application
