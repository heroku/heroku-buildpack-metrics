#!/bin/bash

export HEROKU_PROM_METRICS_ENDPOINT=${HEROKU_PROM_METRICS_ENDPOINT:-/metrics}
export HEROKU_PROM_METRICS_PORT=$(get-random-port)
export HEROKU_PROM_METRICS_POLL_INTERVAL=${HEROKU_PROM_METRICS_POLL_INTERVAL:-5}

if [ -z "$HEROKU_METRICS_USE_STATSD" ]; then
	metrics-poller \
		-scrape-url "http://localhost:${HEROKU_PROM_METRICS_PORT}${HEROKU_PROM_METRICS_ENDPOINT}" \
		-url $HEROKU_METRICS_URL \
		-instance ${DYNO} \
		-interval ${HEROKU_PROM_METRICS_POLL_INTERVAL} &
else
	export HEROKU_STATSD_PORT=$(get-random-port)
	statsdaemon -address ":${HEROKU_STATSD_PORT}" -export-url ${HEROKU_METRICS_URL} -instance ${DYNO} &
fi  
