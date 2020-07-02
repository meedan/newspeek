ifndef MAKE_CMD
	MAKE_CMD=run_worker
endif
run: wait
	make $(MAKE_CMD)
start_server:
	bundle exec rackup -o 0.0.0.0
collect_all:
	bundle exec rake collect_all
run_worker:
	bundle exec sidekiq -r ./environment.rb -c 5
test:
	bundle exec rake test
wait:
	until curl --silent -XGET --fail $(ELASTICSEARCH_URL); do printf '.'; sleep 1; done