require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task default: [:spec, :e2e, :examples]

task :e2e do
  require_relative "e2e/tests"
end

task :examples do
  require_relative "e2e/examples"
end
