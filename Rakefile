require 'rake'
require "rspec/core/rake_task"
load 'environment.rb'

RSpec::Core::RakeTask.new(:test) do |t|
  t.pattern = Dir.glob('spec/**/*_test.rb')
end

task :list_datasource do
  puts ReviewParser.subclasses.collect(&:service)
end

task :collect_datasource do
  ARGV.each { |a| task a.to_sym do ; end }
  datasource = ARGV[1]
  ReviewParser.run(datasource)
end

task :collect_all do
  Parallel.map(ReviewParser.subclasses.collect(&:service), in_processes: 20, progress: "Updating Claims") { |datasource|
    puts "Updating #{datasource}..."
    ReviewParser.run(datasource)
  }
end

task :default => [:test]
