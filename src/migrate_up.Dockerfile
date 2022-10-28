FROM crystallang/crystal:1.2.1-alpine
ADD . /src
WORKDIR /src

# Add trusted CAs for communicating with external services
RUN apk update && apk add --no-cache ca-certificates tzdata && update-ca-certificates

# Install any additional dependencies
# RUN apk add libssh2 libssh2-dev

# Create a non-privileged user
# defaults are appuser:10001
ARG IMAGE_UID="10001"
ENV UID=$IMAGE_UID
ENV USER=appuser

# RUN set -ex && apk add perl-archive-zip
# RUN crc32 shard.yml

# RUN set -ex \
#     && apk add --no-cache imagemagick-dev libtool \
#     && apk add --no-cache --virtual .imagick-runtime-deps imagemagick
# # RUN convert -help

# RUN set -ex && apk add file
# RUN file --help

# See https://stackoverflow.com/a/55757473/12429735RUN
RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/nonexistent" \
    --shell "/sbin/nologin" \
    --no-create-home \
    --uid "${UID}" \
    "${USER}"

# Build App
RUN shards build migrate_up --error-trace --production

# Extract dependencies
RUN ldd bin/migrate_up | tr -s '[:blank:]' '\n' | grep '^/' | \
    xargs -I % sh -c 'mkdir -p $(dirname deps%); cp % deps%;'

# Build a minimal docker image
FROM scratch
WORKDIR /
ENV PATH=$PATH:/
COPY --from=0 /src/deps /
COPY --from=0 /src/bin/migrate_up /migrate_up
# COPY --from=0 /src/public /public
COPY --from=0 /etc/hosts /etc/hosts

# These provide certificate chain validation where communicating with external services over TLS
COPY --from=0 /etc/ca-certificates* /etc/
COPY --from=0 /etc/ssl/ /etc/ssl/
COPY --from=0 /usr/share/ca-certificates/ /usr/share/ca-certificates/

# This is required for Timezone support
COPY --from=0 /usr/share/zoneinfo/ /usr/share/zoneinfo/

# Copy the user information over
COPY --from=0 /etc/passwd /etc/passwd
COPY --from=0 /etc/group /etc/group

# Use an unprivileged user.
USER appuser:appuser

ENV APP_DOMAIN=127.0.0.1
ENV KEMAL_ENV production
ENV APP_ENV production

# localhost ip: ip route show 0.0.0.0/0 | grep -Eo 'via \S+' | awk '{ print $2 }'
# ENV PG_URL postgresql://kpbb:password@127.0.0.404:5432/kpbb?sslmode=require
# ENV PG_URL=postgresql://kpbb:kpbb@localhost:5433/kpbb?sslmode=require
# ENV PG_URL=postgresql://kpbb:kpbb@192.168.0.1:5433/kpbb?sslmode=require
# ENV PG_URL=postgresql://kpbb:password@127.0.0.404:5432/kpbb?sslmode=require
# ENV PG_URL=postgresql://username:password@127.0.0.404:5432/dbname?sslmode=require
ENV PG_URL=postgresql://kpbb:password@127.0.0.404:5432/kpbb?sslmode=require

# ENV APP_COOKIE_SECRET ae76eaa93c4cb773124ada28826d395f
ENV COOKIE_SECRET=RWnuS48aRsFq4oEvOY66OJl0WGh3jiFRpblszy5Q
# ENV COOKIE_DOMAIN=kbb-abcdefghij-ue.a.run.app
# ENV BASE_URL=https://kpbb-abcdefghij-ue.a.run.app
ENV SENTRY_DSN=https://REDACTED@REDACTED.ingest.sentry.io/REDACTED
ENV SENTRY_ORG=codebro
# https://sentry.io/organizations/kpbb/issues/?project=5735
ENV SENTRY_PROJECT=kpbb
ENV SENTRY_AUTH_TOKEN=REDACTED
ENV PORT 8080
ENV APP_NAME kpbb
ENV KPBB_IMG_API https://kpbb-img-abcdefghij-ue.a.run.app
ENV UNFURL_API https://us-west1-REDACTED_GOOGLE_CLOUD_PROJECT_ID.cloudfunctions.net/unfurl
ENV IMAGICK_API https://us-west1-REDACTED_GOOGLE_CLOUD_PROJECT_ID.cloudfunctions.net/imagick
# ENV TWITTER_SS_API https://us-west1-REDACTED_GOOGLE_CLOUD_PROJECT_ID.cloudfunctions.net/twitter_ss
ENV YOUTUBE_API_KEY=REDACTED_YTKEY
ENV RAVEN_OS_CONTEXT_EXEC=alpine-kpbb-migrate-up

# Run the app binding on port 8080
EXPOSE 8080
ENTRYPOINT ["/migrate_up"]
# HEALTHCHECK CMD ["/migrate_up", "-c", "http://127.0.0.1:8080/"]
CMD ["/migrate_up"]
