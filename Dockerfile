FROM sameersbn/gitlab:16.6.1

# Override files
COPY assets/runtime/config/gitlabhq/gitlab.yml ${GITLAB_RUNTIME_DIR}/config/gitlabhq/gitlab.yml
COPY assets/runtime/functions ${GITLAB_RUNTIME_DIR}/functions
