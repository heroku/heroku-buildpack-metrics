#!/bin/bash

export HEROKU_STATSD_PORT=$(get-random-port)
statsdaemon -address ":$HEROKU_STATSD_PORT" -export-url $HEROKU_METRICS_URL -instance $DYNO &
