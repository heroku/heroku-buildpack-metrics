#!/bin/bash

export HEROKU_PROM_METRICS_ENDPOINT=${HEROKU_PROM_METRICS_ENDPOINT:-/metrics}
export HEROKU_PROM_METRICS_PORT=$(./bin/get-random-port)
export HEROKU_PROM_METRICS_POLL_INTERVAL=${HEROKU_PROM_METRICS_POLL_INTERVAL:-5}

if [ -f pom.xml ]; then
	export JAVA_TOOL_OPTIONS="-javaagent:bin/heroku-metrics-agent.jar ${JAVA_TOOL_OPTIONS}"
fi

if [ -z "$HEROKU_METRICS_USE_STATSD" ]; then
	./bin/metrics-poller \
		-scrape-url "http://localhost:${HEROKU_PROM_METRICS_PORT}${HEROKU_PROM_METRICS_ENDPOINT}" \
		-url $HEROKU_METRICS_URL \
		-instance ${DYNO} \
		-interval ${HEROKU_PROM_METRICS_POLL_INTERVAL} &
else
	export HEROKU_STATSD_PORT=$(get-random-port)
	./bin/statsdaemon -address ":${HEROKU_STATSD_PORT}" -export-url ${HEROKU_METRICS_URL} -instance ${DYNO} &
fi
