# frozen_string_literal: true

require('rake')
require('rspec/core/rake_task')
load('environment.rb')

RSpec::Core::RakeTask.new(:test) do |t|
  test_files = Dir.glob('spec/**/*_test.rb')
  test_files = test_files.reject{|t| t.include?("_integration_test.rb")} if !Settings.in_integration_test_mode?
  t.pattern = test_files
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
  overwrite_existing_claims = ARGV[3] == "true"
  RunClaimReviewParser.perform_async(datasource, cursor_back_to_date, overwrite_existing_claims)
end

task :collect_all do
  ARGV.each do |a|
    task a.to_sym do
    end
  end
  cursor_back_to_date = ARGV[1]
  overwrite_existing_claims = ARGV[2] == "true"
  ClaimReviewParser.subclasses.map(&:service).each do |datasource|
    puts "Updating #{datasource}..."
    RunClaimReviewParser.perform_async(datasource, cursor_back_to_date, overwrite_existing_claims)
  end
end

task :init_index do
  ClaimReviewRepository.init_index
end

task(default: [:test])
