#!/bin/bash

set -e

if [[ -z ${GITHUB_TOKEN+x} || -z ${DEPLOY_ENV+x} || -z ${APP+x} ]]; then
	echo "GITHUB_TOKEN, DEPLOY_ENV and APP must be in the environment.   Exiting."
	exit 1
fi

if [[ "$DEPLOY_ENV" != "qa" && "$DEPLOY_ENV" != "live" ]]; then
	# Only use the test configurations if we're not deploying to QA or Live.
	cp config/cookies.json.example config/cookies.json
	cp .env_file.test .env_file
fi
