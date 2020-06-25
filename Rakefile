# frozen_string_literal: true

require('rake')
require('rspec/core/rake_task')
load('environment.rb')

RSpec::Core::RakeTask.new(:test) do |t|
  t.pattern = Dir.glob('spec/**/*_test.rb')
end

task :list_datasource do
  puts ReviewParser.subclasses.map(&:service)
end

task :collect_datasource do
  ARGV.each { |a| task a.to_sym do; end }
  datasource = ARGV[1]
  RunReviewParser.perform_async(datasource)
end

task :collect_all do
  Parallel.map(ReviewParser.subclasses.map(&:service), in_processes: 20, progress: 'Updating Claims') do |datasource|
    puts "Updating #{datasource}..."
    RunReviewParser.perform_async(datasource)
  end
end

task(default: [:test])
