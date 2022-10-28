# KPBB - (abandoned)

Originally stood for "Kemal Parrot Bulletin Board", but was not intended to release under that name.

It was intented to be a general self-hosted Twitter/Reddit/Tumblr alternative with a focus on minimal use of javascript. Think if hackernews decided to have more features without becoming a giant SPA or abandoning it's minimalism.

Autoposting into KPBB from external RSS feeds and webhooks work well, everything else will probably need polishing or implementing. Funny enough, outbound RSS feeds were never implemented.

Some of the SQL/ORM stuff was written before I fully understood the `DB` and `PG` modules, and some ORMs either didn't work or were too magical to use. Sentry (aka raven) logs DB queries for exceptions.

Majority of the code was written in 0.35, but some updates were made for 1.2.1

## Documentation

```bash
# run server locally
sh/dev

# run cron locally
sh/dev_cron
```

## Testing

take a look at my util functions for snapshots `src/iomcr/snapshot/`.

Test coverage is very high.
```bash
# run tests once
sh/test

# automatically re-run tests on file changes
sh/watch_test
```

There is a `gitlab-ci.yml`, so if you upload this to gitlab I don't know if it will run the tests automatically.

## Compiling

See the Dockerfiles or `sh/*` files.

### Deploying

Application was designed to run on Google Cloud Run or a VPS. Docker is optional for the VPS. The `./functions` directory is required for some features to work correctly, but application is still usable without them. Basically just deploy them as google cloud function and put their URLs in your .env or environment.

If you do not want to put this behind cloudflare, you would need to spoof the `cf-ipcountry` header or remove the code related to it or set the .env value `SPOOF_CFIPCC=us`.

`cloudbuild.yaml` for Google Cloud probably does not work correctly/completely.

Note that server, cron, and migrate_up are seperate binaries.