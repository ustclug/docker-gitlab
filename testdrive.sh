#!/bin/bash -ex
docker run --name gitlab-postgresql -d \
    --env 'DB_NAME=gitlabhq_production' \
    --env 'DB_USER=gitlab' --env 'DB_PASS=password' \
    --env 'DB_EXTENSION=pg_trgm,btree_gist' \
    --volume /srv/docker/gitlab/postgresql:/var/lib/postgresql \
    sameersbn/postgresql:14-20230628
docker run --name gitlab-redis -d \
    --volume /srv/docker/gitlab/redis:/data \
    redis:6.2
docker run --name gitlab \
    --link gitlab-postgresql:postgresql --link gitlab-redis:redisio \
    --publish 10022:22 --publish 10080:80 \
    --env 'GITLAB_PORT=10080' --env 'GITLAB_SSH_PORT=10022' \
    --env 'GITLAB_SECRETS_DB_KEY_BASE=long-and-random-alpha-numeric-string' \
    --env 'GITLAB_SECRETS_SECRET_KEY_BASE=long-and-random-alpha-numeric-string' \
    --env 'GITLAB_SECRETS_OTP_KEY_BASE=long-and-random-alpha-numeric-string' \
    --env OAUTH2_GENERIC_USTC_APP_ID=1234 \
    --env OAUTH2_GENERIC_USTC_APP_SECRET=example \
    --env 'OAUTH2_GENERIC_USTC_LABEL=example oauth' \
    --env OAUTH2_GENERIC_USTC_CLIENT_SITE=https://example.com \
    --env OAUTH2_GENERIC_USTC_CLIENT_USER_INFO_URL=/userinfo \
    --env OAUTH2_GENERIC_USTC_CLIENT_AUTHORIZE_URL=/authorize \
    --env OAUTH2_GENERIC_USTC_CLIENT_TOKEN_URL=/token \
    --env OAUTH2_GENERIC_USTC_ID_PATH=gid \
    --volume /srv/docker/gitlab/gitlab:/home/git/data \
    "$IMAGE_NAME":"$TAG" &
echo "Please wait 4 minutes..."
sleep 4m
url="http://localhost:10080"
status_code=$(curl --write-out '%{http_code}' --silent --output /dev/null "$url")
# Check if the status code is not in the success range (200-299)
if [[ $status_code -lt 200 || $status_code -gt 399 ]]; then
    echo "Error: Failed to access $url (status code: $status_code)"
    exit 1
fi
ret=$(docker exec gitlab cat /home/git/gitlab/config/gitlab.yml | grep -c 'example oauth')
if [[ $ret -ne 1 ]]; then
    echo "Error: Failed to find 'example oauth' in gitlab.yml"
    exit 1
fi