## Claim Review API

[![Code Climate](https://codeclimate.com/repos/TODO/badges/TODO/gpa.svg)](https://codeclimate.com/repos/TODO/feed)
[![Test Coverage](https://codeclimate.com/repos/TODO/badges/TODO/coverage.svg)](https://codeclimate.com/repos/TODO/coverage)
[![Issue Count](https://codeclimate.com/repos/TODO/badges/TODO/issue_count.svg)](https://codeclimate.com/repos/TODO/feed)
[![Travis](https://travis-ci.org/meedan/claim-review-api.svg?branch=develop)](https://travis-ci.org/meedan/check-api/)

A Fact / Claim Review aggregation service.

## Development

- `docker-compose build`
- `docker-compose up`
- Open http://localhost:9292/about for the Claim Review API
- Open http://localhost:5601 for the Kibana UI
- Open http://localhost:9200 for the Elasticsearch API
- `docker-compose exec claim_review_api bash` to get inside the claim review API bash and directly debug issues.

## Testing

- `MAKE_CMD=test docker-compose up` #NOTE THAT THIS IS NOT ACTUALLY WORKING RIGHT NOW

## To-do:

1. Finish integrations with code climate / rubocop / travis
2. Slight modification to Docker setup to allow running tests or server or worker according to commands passed in
3. Errbit integration?
4. Deployment automation with gitlab
5. add webhooks for subscribing to claim reviews