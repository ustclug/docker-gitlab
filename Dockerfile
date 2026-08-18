FROM ghcr.io/2403772980ygy/docker-gitlab:19.2.4

# Override files
COPY assets/runtime/config/gitlabhq/gitlab.yml ${GITLAB_RUNTIME_DIR}/config/gitlabhq/gitlab.yml
COPY assets/runtime/config/nginx/gitlab ${GITLAB_RUNTIME_DIR}/config/nginx/gitlab
COPY assets/runtime/functions ${GITLAB_RUNTIME_DIR}/functions
