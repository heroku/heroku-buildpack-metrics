# heroku-buildpack-metrics

For use with the `heroku-metrics` addon (still in alpha)

## Step 1: Add the addon / buildpack
```
cd ~/path/to/heroku-app
heroku addons:create heroku-metrics:test
heroku buildpacks:add https://github.com/cyx/heroku-buildack-metrics
```

## Step 2: Update your Procfile

If it was something like this before:

```
web: rackup -p $PORT
```

Simply change it to:

```
web: begin rackup -p $PORT
```

The `begin` bash wrapper will simply start up the `statsdaemon`, which you can post things to in `localhost:8125`.
See the relevant docs on `statsd` for how to post to the UDP protocol.

## Step 3: Redeploy your app

```
git push heroku master
```
