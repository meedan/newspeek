# frozen_string_literal: true

require('sinatra')
require('rack')
load('environment.rb')

set(:root, File.dirname(__FILE__))
set(:environment, :local)
set(:run, false)
run(Site)
