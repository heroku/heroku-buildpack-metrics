# heroku-buildpack-metrics

For use with the `heroku-metrics` addon (still in alpha)

## Step 1: Add the addon / buildpack
```
cd ~/path/to/heroku-app
heroku addons:create heroku-metrics:test
heroku buildpacks:add https://github.com/cyx/heroku-buildpack-metrics
```

## Step 2: Redeploy your app

```
git push heroku master
```

## Step 3: Start shipping metrics to `localhost:8125`

Use your favorite statds client of choice for that.
