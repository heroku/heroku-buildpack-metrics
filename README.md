# heroku-buildpack-metrics

This buildpack sets up the necessary machinery to
utilize
[Heroku's Language Metrics](https://devcenter.heroku.com/articles/language-runtime-metrics) feature.

## How does it affect my slug?

This buildpack copies a [.profile.d/](https://devcenter.heroku.com/articles/dynos#the-profile-file) script into your slug. The [.profile.d/](https://devcenter.heroku.com/articles/dynos#the-profile-file) script downloads the latest agentmon release, and
starts it on Dyno boot.

## Releasing

If you belong to the Heroku org, you can release a new version of the buildpack
by running the following command:

```
$ git tag vXXX
$ heroku buildpacks:publish heroku/metrics vXXX
```

This will publish the tag `vXXX` as a new version of the
`heroku/metrics` buildpack. If you get a 401 you may not have the right
permissions to publish. Check with @jkutner

## Testing

This buildpack uses [Hatchet](https://github.com/heroku/hatchet) to run integration tests. To run them local
make sure you have [Ruby](https://www.ruby-lang.org/) installed, then execute:

```sh-session
$ bundle install
$ bundle exec rspec spec/
```
