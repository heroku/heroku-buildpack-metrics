#!/bin/bash

export HEROKU_METRICS_ENDPOINT=${HEROKU_METRICS_ENDPOINT:-/metrics}
export HEROKU_METRICS_POLL_INTERVAL=${HEROKU_METRICS_POLL_INTERVAL:-5}

if [ -z "$HEROKU_METRICS_USE_STATSD" ]; then
	metrics-poller \
		-scrape-url "http://localhost:${PORT}${HEROKU_METRICS_ENDPOINT}" \
		-url $HEROKU_METRICS_URL \
		-instance ${DYNO} \
		-interval ${HEROKU_METRICS_POLL_INTERVAL} &
else
	export HEROKU_STATSD_PORT=$(get-random-port)
	statsdaemon -address ":${HEROKU_STATSD_PORT}" -export-url ${HEROKU_METRICS_URL} -instance ${DYNO} &
fi  
