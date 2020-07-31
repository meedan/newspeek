## Fetch
[![Code Climate](https://api.codeclimate.com/v1/badges/42a4437feae3058176ff/maintainability)](https://codeclimate.com/repos/5ef4a2779226cb00dd00473b/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/42a4437feae3058176ff/test_coverage)](https://codeclimate.com/repos/5ef4a2779226cb00dd00473b/test_coverage)
[![Travis](https://travis-ci.org/meedan/fetch.svg?branch=develop)](https://travis-ci.org/meedan/fetch)

A Fact / Claim Review aggregation service.

## Development

- `docker-compose build`
- `docker-compose up`
- Open http://localhost:9292/about for the Claim Review API
- Open http://localhost:5601 for the Kibana UI
- Open http://localhost:9200 for the Elasticsearch API
- `docker-compose exec fetch bash` to get inside the claim review API bash and directly debug issues.

## Testing

- `docker-compose run fetch test`

## Rake Tasks

`bundle exec rake test` - run test suite
`bundle exec rake list_datasources` - list all services currently implemented in `fetch`
`bundle exec rake collect_datasource [service] [cursor_back_to_date] [overwrite_existing_claims]` - initiate crawl on `service` that optionally forces collection back to a `Time`-parseable `cursor_back_to_date`. Optionally allow `overwrite_existing_claims` - can be `true` or `false` - if true, will overwrite documents - useful for addressing issues with malformed existing documents.
`bundle exec rake collect_all [cursor_back_to_date] [overwrite_existing_claims]` - Kickoff crawl for all currently-implemented services. Optionally allow `overwrite_existing_claims` - can be `true` or `false` - if true, will overwrite documents - useful for addressing issues with malformed existing documents.

## To-do:

0. Get added to ~Code Climate~, ~Travis~, ~Errbit~
1. ~Write per page result rather than waiting to write all documents at the end.~
2. ~Convert tasks to run via Sidekiq~
3. ~Add cursor_back_to_time option to bypass stopping when all URLs are found on a page~
4. ~Upload schema file to index and create index with JSON file, do this via Docker~
5. ~Persist Raw Claims where Raw Claims were ClaimReview compliant cases~
6. Finish integrations with ~Code Climate~ / ~Rubocop~ / ~Travis~
7. ~Slight modification to Docker setup to allow running tests or server or worker according to commands passed in~
8. ~Errbit integration?~
9. Deployment automation with GitHub Actions
10. ~Add webhooks for subscribing to data updates~
11. ~Generate "pristine" dataset of all facts and provide to staging / prod to prevent re-mining exact same data~
12. ~Get back to 100% code coverage~
