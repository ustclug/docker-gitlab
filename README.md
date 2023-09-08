# docker-gitlab

Customized gitlab container image based on <https://github.com/sameersbn/docker-gitlab>.

## Update version

1. Update version number in `.gitlab-version`
2. Update `FROM` in `Dockerfile`

## Changes

### Generic OAuth2 for USTC CAS

Changes to assets/runtime/config/gitlabhq/gitlab.yml:

```yaml
- { name: 'oauth2_generic',
    app_id: '{{OAUTH2_GENERIC_USTC_APP_ID}}',
    app_secret: '{{OAUTH2_GENERIC_USTC_APP_SECRET}}',
    label: '{{OAUTH2_GENERIC_USTC_LABEL}}',
    args: {
    client_options: {
        site: '{{OAUTH2_GENERIC_USTC_CLIENT_SITE}}',
        user_info_url: '{{OAUTH2_GENERIC_USTC_CLIENT_USER_INFO_URL}}',
        authorize_url: '{{OAUTH2_GENERIC_USTC_CLIENT_AUTHORIZE_URL}}',
        token_url: '{{OAUTH2_GENERIC_USTC_CLIENT_TOKEN_URL}}',
    },
    authorize_params: {
        scope: "snsapi_userinfo",
        appid: {{OAUTH2_GENERIC_USTC_APP_ID}},
    },
    token_params: {
        appid: {{OAUTH2_GENERIC_USTC_APP_ID}},
        secret: '{{OAUTH2_GENERIC_USTC_APP_SECRET}}',
    },
    strategy_class: "OmniAuth::Strategies::OAuth2Generic",
    user_response_structure: {
        attributes: {},
        id_path: '{{OAUTH2_GENERIC_USTC_ID_PATH}}' } } }
```

Changes to assets/runtime/functions (`gitlab_configure_oauth_azure_ad_v2` is replaced by `gitlab_configure_oauth2_generic_ustc`):

```bash
gitlab_configure_oauth2_generic_ustc() {
  if [[ -n ${OAUTH2_GENERIC_USTC_APP_ID} && \
        -n ${OAUTH2_GENERIC_USTC_APP_SECRET} ]]; then
    echo "Configuring gitlab::oauth::generic..."
    OAUTH_ENABLED=${OAUTH_ENABLED:-true}
    update_template ${GITLAB_CONFIG} \
    OAUTH2_GENERIC_USTC_APP_ID \
    OAUTH2_GENERIC_USTC_APP_SECRET \
    OAUTH2_GENERIC_USTC_LABEL \
    OAUTH2_GENERIC_USTC_CLIENT_SITE \
    OAUTH2_GENERIC_USTC_CLIENT_USER_INFO_URL \
    OAUTH2_GENERIC_USTC_CLIENT_AUTHORIZE_URL \
    OAUTH2_GENERIC_USTC_CLIENT_TOKEN_URL \
    OAUTH2_GENERIC_USTC_ID_PATH
  else
      exec_as_git sed -i "/name: 'oauth2_generic'/,/{{OAUTH2_GENERIC_USTC_ID_PATH}}/d" ${GITLAB_CONFIG}
  fi
}
```

`gitlab_configure_oauth2_generic` is commented out.

`user_info_url` (env `OAUTH2_GENERIC_USTC_CLIENT_USER_INFO_URL`) should be pointed to the container of <https://github.com/ustclug/userinfo-proxy/>.

## Self-help debugging

```bash
# run container with specific environment variables LOCALLY to check if the modification is correct
$ sudo docker run \
    -e OAUTH2_GENERIC_USTC_APP_ID=1234 \
    -e OAUTH2_GENERIC_USTC_APP_SECRET=example \
    -e 'OAUTH2_GENERIC_USTC_LABEL=example oauth' \
    -e OAUTH2_GENERIC_USTC_CLIENT_SITE=https://example.com \
    -e OAUTH2_GENERIC_USTC_CLIENT_USER_INFO_URL=/userinfo \
    -e OAUTH2_GENERIC_USTC_CLIENT_AUTHORIZE_URL=/authorize \
    -e OAUTH2_GENERIC_USTC_CLIENT_TOKEN_URL=/token \
    -e OAUTH2_GENERIC_USTC_ID_PATH=gid \
    --name=gitlab-test -it local/gitlab:16.3.0 bash
# source "${GITLAB_RUNTIME_DIR}/functions"
Loading /etc/docker-gitlab/runtime/env-defaults
# set +e
# initialize_system
Initializing logdir...
Initializing datadir...
Container TimeZone -> UTC
Installing configuration templates...
# gitlab_configure_oauth
Configuring gitlab::oauth...
Configuring gitlab::oauth::generic_ustc...
# cat /home/git/gitlab/config/gitlab.yml
```