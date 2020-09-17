SHELL := /bin/bash

configurator:
ifeq (,$(wildcard .env_file))
	production/bin/configurator.sh
else
	$(info Configuration exists.)
endif

start_server: configurator
	set -o allexport && source .env_file && set +o allexport && bundle exec rackup -o 0.0.0.0

collect_all: configurator
	set -o allexport && source .env_file && set +o allexport && bundle exec rake collect_all

run_worker: configurator
	set -o allexport && source .env_file && set +o allexport && bundle exec sidekiq -r ./environment.rb -c 5

test: configurator
	bundle exec rake test

test_unit: configurator
	bundle exec rake test:unit

test_integration: configurator
	bundle exec rake test:integration
