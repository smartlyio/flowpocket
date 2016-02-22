# Flowpocket

Post tagged messages from Flowdock to Pocket.

## Dependencies

* Ruby
* Redis

## API tokens

Flowpocket requires three tokens to work. These tokens are set up using environment variables.

* FLOWDOCK_API_TOKEN - API token of a Flowdock user account
* POCKET_CONSUMER_KEY - Consumer key of a registered Pocket app
* POCKET_ACCESS_TOKEN - A user access token for a the registered app

To set up Pocket tokens, follow the instructions at [Pocket API Authentication](https://getpocket.com/developer/docs/authentication). Flowdock API token can be found from account [api tokens page](https://www.flowdock.com/account/tokens).

Additionally you can set up `FLOWDOCK_ORGANIZATION` environment variable to limit the integration to the specified organization.

## Running

```
$ foreman start
```

This will run the script once and terminate. Run the script periodically with cron or some other scheduler.

## Deployment

We deploy the script to Heroku. Using Heroku Scheduler add-on the script is run every 10 minutes.
