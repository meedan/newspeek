# frozen_string_literal: true

require 'time'
require 'csv'
require 'json'
require 'logger'

require 'faraday'
require 'sinatra'
require 'pry'
require 'sidekiq'
require 'hashie'
require 'nokogiri'
require 'cld'
require 'parallel'
require 'dgaff'
require 'restclient'
require 'fuzzystringmatch'
require 'matrix'
require 'tf-idf-similarity'
require 'elasticsearch'
require 'elasticsearch/dsl'
require 'elasticsearch/persistence'

SETTINGS = JSON.parse(File.read(ENV['settings_filename'] || 'settings.json'))
Dir[File.dirname(__FILE__) + '/extensions/*.rb'].sort.each { |file| require file }
Dir[File.dirname(__FILE__) + '/models/*.rb'].sort.each { |file| require file }
Dir[File.dirname(__FILE__) + '/lib/*.rb'].sort.each { |file| require file }
Dir[File.dirname(__FILE__) + '/tasks/*.rb'].sort.each { |file| require file }
Dir[File.dirname(__FILE__) + '/lib/review_parsers/*.rb'].sort.each { |file| require file }
