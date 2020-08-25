#!/bin/bash

set -e

if [[ -z ${CONFIGURATOR_TOKEN+x} || -z ${DEPLOY_ENV+x} || -z ${APP+x} ]]; then
	echo "CONFIGURATOR_TOKEN, DEPLOY_ENV and APP must be in the environment.   Exiting."
	exit 1
fi

if [ ! -d "configurator" ]; then git clone -q https://${CONFIGURATOR_TOKEN}:x-oauth-basic@github.com/meedan/configurator ./configurator; fi
d=configurator/check/${DEPLOY_ENV}/${APP}/; for f in $(find $d -type f); do cp "$f" "${f/$d/}"; done

