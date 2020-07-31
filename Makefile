configurator:
ifeq (,$(wildcard .env_file))
	production/bin/configurator.sh
else
	$(info Configuration exists.)
endif
start_server: configurator
	bundle exec rackup -o 0.0.0.0
collect_all: configurator
	bundle exec rake collect_all
run_worker: configurator
	bundle exec sidekiq -r ./environment.rb -c 5
test:
	bundle exec rake test
