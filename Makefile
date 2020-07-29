wait:
	until curl --silent -XGET --fail $(es_host); do printf '.'; sleep 1; done
configurator:
  git clone -q https://${GITHUB_TOKEN}:x-oauth-basic@github.com/meedan/configurator ./configurator
  d=configurator/check/${DEPLOY_ENV}/${APP}/; for f in $(find $d -type f); do cp "$f" "${f/$d/}"; done
start_server: wait
	bundle exec rackup -o 0.0.0.0
collect_all: wait
	bundle exec rake collect_all
run_worker: wait
	bundle exec sidekiq -r ./environment.rb -c 5
test:
	bundle exec rake test
