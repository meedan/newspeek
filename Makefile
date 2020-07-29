wait:
	until curl --silent -XGET --fail $(es_host); do printf '.'; sleep 1; done
configurator:
ifeq (,$(wildcard .env_file))
	production/bin/configurator.sh
else
	$(info Configuration exists.)
endif
start_server: configurator wait
	bundle exec rackup -o 0.0.0.0
collect_all: configurator wait
	bundle exec rake collect_all
run_worker: configurator wait
	bundle exec sidekiq -r ./environment.rb -c 5
test:
	bundle exec rake test
