# frozen_string_literal: true

require('rake')
require('rspec/core/rake_task')
load('environment.rb')

RSpec::Core::RakeTask.new(:test) do |t|
  t.pattern = Dir.glob('spec/**/*_test.rb')
end

task :list_datasources do
  puts ClaimReviewParser.subclasses.map(&:service)
end

task :collect_datasource do
  ARGV.each do |a|
    task a.to_sym do
    end
  end
  datasource = ARGV[1]
  cursor_back_to_date = ARGV[2]
  RunClaimReviewParser.perform_async(datasource, cursor_back_to_date)
end

task :collect_all do
  ARGV.each do |a|
    task a.to_sym do
    end
  end
  cursor_back_to_date = ARGV[1]
  ClaimReviewParser.subclasses.map(&:service).each do |datasource|
    puts "Updating #{datasource}..."
    RunClaimReviewParser.perform_async(datasource, cursor_back_to_date)
  end
end

task(default: [:test])
