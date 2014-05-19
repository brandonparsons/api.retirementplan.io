desc "Checks runtime ruby version"
task :check_ruby_version do
  puts `ruby -v`
end

desc "Spews a bunch of environment info"
task :info do
  puts `ruby -v`
  puts ENV.inspect
end

desc "Runs brakeman"
task :brakeman do
  `bundle exec brakeman -f html -o brakeman.html`
end
