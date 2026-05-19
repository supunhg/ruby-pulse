require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task default: :spec

desc "Run the application"
task :run do
  ruby "app/main.rb"
end

desc "Bootstrap development environment"
task :bootstrap do
  sh "bundle install"
  sh "mkdir -p data log tmp"
end
