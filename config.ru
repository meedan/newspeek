# frozen_string_literal: true

require('sinatra')
require('rack')
load('environment.rb')
set(:root, File.dirname(__FILE__))
set(:environment, :development)
set(:run, false)
run(Site)
