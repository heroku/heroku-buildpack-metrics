#!/bin/bash

# don't do anything if we don't have a metrics url.
if [ -z "$HEROKU_METRICS_URL" ]; then
    exit 1
fi

export HEROKU_METRICS_PROM_ENDPOINT=${HEROKU_METRICS_PROM_ENDPOINT:-/metrics}
export HEROKU_METRICS_PROM_PORT=$(expr $PORT + 1)
export HEROKU_PROM_METRICS_ENDPOINT=${HEROKU_METRICS_PROM_ENDPOINT}
export HEROKU_PROM_METRICS_PORT=${HEROKU_METRICS_PROM_PORT}

if [ -f pom.xml ]; then
    export JAVA_TOOL_OPTIONS="-javaagent:bin/heroku-metrics-agent.jar ${JAVA_TOOL_OPTIONS}"
    AGENTMON_FLAGS="-prom-url http://localhost:${HEROKU_METRICS_PROM_PORT}${HEROKU_METRICS_PROM_ENDPOINT}"
else
    AGENTMON_FLAGS="-statsd-addr :${PORT}"
fi

if [ "${AGENTMON_DEBUG}" = "true" ]; then
    AGENTMON_FLAGS="${AGENTMON_FLAGS} -debug"
fi

if [ -x "./bin/agentmon" ]; then
    (while true; do
        ./bin/agentmon ${AGENTMON_FLAGS} ${HEROKU_METRICS_URL}
        echo "agentmon completed with status=${?}. Restarting"
        sleep 1
    done) &
else
    echo "No agentmon executable found. Not starting."
fi
