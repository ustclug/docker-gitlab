#!/bin/bash -ex

SUFFIX="$RANDOM"

cleanup() {
    docker stop "gitlab-${SUFFIX}" || kill -TERM "$(jobs -pr)" || true
    docker stop "gitlab-redis-${SUFFIX}" || true
    docker stop "gitlab-postgresql-${SUFFIX}" || true
}

trap cleanup EXIT

docker run --rm --name "gitlab-postgresql-${SUFFIX}" -d \
    --env 'DB_NAME=gitlabhq_production' \
    --env 'DB_USER=gitlab' --env 'DB_PASS=password' \
    --env 'DB_EXTENSION=pg_trgm,btree_gist' \
    sameersbn/postgresql:14-20230628
docker run --rm --name "gitlab-redis-${SUFFIX}" -d \
    --volume /srv/docker/gitlab/redis:/data \
    redis:6.2
docker run --rm --name "gitlab-${SUFFIX}" \
    --link "gitlab-postgresql-${SUFFIX}:postgresql" --link "gitlab-redis-${SUFFIX}:redisio" \
    --publish 10022:22 --publish 10080:80 \
    --env 'GITLAB_PORT=10080' --env 'GITLAB_SSH_PORT=10022' \
    --env 'GITLAB_SECRETS_DB_KEY_BASE=long-and-random-alpha-numeric-string' \
    --env 'GITLAB_SECRETS_SECRET_KEY_BASE=long-and-random-alpha-numeric-string' \
    --env 'GITLAB_SECRETS_OTP_KEY_BASE=long-and-random-alpha-numeric-string' \
    --env 'GITLAB_SECRETS_ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=long-and-random-alpha-numeric-string' \
    --env 'GITLAB_SECRETS_ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=long-and-random-alpha-numeric-string' \
    --env 'GITLAB_SECRETS_ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=long-and-random-alpha-numeric-string' \
    --env OAUTH2_GENERIC_USTC_APP_ID=1234 \
    --env OAUTH2_GENERIC_USTC_APP_SECRET=example \
    --env 'OAUTH2_GENERIC_USTC_LABEL=example oauth' \
    --env OAUTH2_GENERIC_USTC_CLIENT_SITE=https://example.com \
    --env OAUTH2_GENERIC_USTC_CLIENT_USER_INFO_URL=/userinfo \
    --env OAUTH2_GENERIC_USTC_CLIENT_AUTHORIZE_URL=/authorize \
    --env OAUTH2_GENERIC_USTC_CLIENT_TOKEN_URL=/token \
    --env OAUTH2_GENERIC_USTC_ID_PATH=gid \
    "$IMAGE_NAME":"$TAG" &

check() {
    local url="http://localhost:10080"
    status_code=$(curl --write-out '%{http_code}' --silent --output /dev/null "$url")
    # Check if the status code is not in the success range (200-399)
    if [[ $status_code -lt 200 || $status_code -gt 399 ]]; then
        echo "Error: Failed to access $url (status code: $status_code)"
        return 1
    fi
    ret=$(docker exec "gitlab-${SUFFIX}" cat /home/git/gitlab/config/gitlab.yml | grep -c 'example oauth')
    if [[ $ret -ne 1 ]]; then
        echo "Error: Failed to find 'example oauth' in gitlab.yml"
        return 1
    fi
    assets_location="/assets/locale/zh_CN/app-45e4963f833169170e6fd77b78bb1758d413a6a676d484235818594551d2e018.js"
    assets_code=$(curl --write-out '%{http_code}' --silent --output /dev/null "$url$assets_location")
    if [[ $assets_code -lt 200 || $assets_code -gt 399 ]]; then
        echo "Error: Failed to access $url$assets_location (status code: $assets_code)"
        return 1
    fi
    return 0
}

RETRIES="48"
RETRIED=0
WAIT_TIME="5s"

until check || { [[ "$((RETRIED++))" == "${RETRIES}" ]] && exit 1; }; do
    sleep "${WAIT_TIME}"
done
