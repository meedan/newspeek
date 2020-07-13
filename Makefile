wait:
	until curl --silent -XGET --fail $(ELASTICSEARCH_URL); do printf '.'; sleep 1; done
start_server: wait
	bundle exec rackup -o 0.0.0.0
collect_all: wait
	bundle exec rake collect_all
run_worker: wait
	bundle exec sidekiq -r ./environment.rb -c 5
test:
	bundle exec rake test
