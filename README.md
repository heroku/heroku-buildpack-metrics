# heroku-buildpack-metrics

This buildpack sets up the necessary machinery to
utilize
[Heroku's Language Metrics](https://devcenter.heroku.com/articles/language-runtime-metrics) feature,
which currently supports the JVM only.

## How does it affect my slug?

This buildpack does two things.

1. Copies a jar into the slug
2. Copies a [.profile.d/](https://devcenter.heroku.com/articles/dynos#the-profile-file) script into your slug

The jar file, when `$HEROKU_METRICS_URL` is set as a result of the
`runtime-heroku-metrics` labs flag, will be used as an agent to your
Java process. This jar exposes metrics via
a [Prometheus](https://prometheus.io/) server which an additional
process, namely [agentmon](https://github.com/heroku/agentmon), will
poll and forward to `$HEROKU_METRICS_URL`, for processing.

The [.profile.d/](https://devcenter.heroku.com/articles/dynos#the-profile-file) script downloads the latest agentmon release, and
starts it on Dyno boot.

