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
    AGENT_MON_FLAGS="-prom-url http://localhost:${HEROKU_METRICS_PROM_PORT}${HEROKU_METRICS_PROM_ENDPOINT}"
else
    AGENT_MON_FLAGS="-statsd-addr :${PORT}"
fi

if [ -x "./bin/agentmon" ]; then
    ./bin/agentmon ${AGENT_MON_FLAGS} ${HEROKU_METRICS_URL}
else
    echo "No agentmon executable found. Not starting."
fi
