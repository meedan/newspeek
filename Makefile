SHELL := /bin/bash

configurator:
ifeq (,$(wildcard .env_file))
	production/bin/configurator.sh
else
	$(info Configuration exists.)
endif

start_server: configurator
	set -o allexport && source .env_file && set +o allexport && bundle exec rackup -o 0.0.0.0

collect_all: 
	set -o allexport && source .env_file && set +o allexport && bundle exec rake collect_all

run_worker: 
	set -o allexport && source .env_file && set +o allexport && bundle exec sidekiq -r ./environment.rb -c 5

test:
	set -o allexport && source .env_file && set +o allexport && bundle exec rake test
