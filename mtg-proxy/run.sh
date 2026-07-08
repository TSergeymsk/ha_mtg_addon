#!/usr/bin/env bashio

CONFIG_DIR="/config"
CONFIG_FILE="${CONFIG_DIR}/mtg.toml"
mkdir -p "${CONFIG_DIR}"

DEBUG=$(bashio::config 'debug')
SECRET=$(bashio::config 'secret')
BIND_TO=$(bashio::config 'bind_to')
CONCURRENCY=$(bashio::config 'concurrency')
PREFER_IP=$(bashio::config 'prefer_ip')
AUTO_UPDATE=$(bashio::config 'auto_update')
TOLERATE_TIME_SKEWNESS=$(bashio::config 'tolerate_time_skewness')
ALLOW_FALLBACK=$(bashio::config 'allow_fallback_on_unknown_dc')

if [ -z "${SECRET}" ] || [ -z "${BIND_TO}" ]; then
    bashio::log.error "secret и bind_to обязательны"
    exit 1
fi

cat > "${CONFIG_FILE}" <<EOF
debug = ${DEBUG}
secret = "${SECRET}"
bind-to = "${BIND_TO}"
concurrency = ${CONCURRENCY}
prefer-ip = "${PREFER_IP}"
auto-update = ${AUTO_UPDATE}
tolerate-time-skewness = "${TOLERATE_TIME_SKEWNESS}"
allow-fallback-on-unknown-dc = ${ALLOW_FALLBACK}
EOF

bashio::log.info "Конфигурация сохранена в ${CONFIG_FILE}"
exec /usr/local/bin/mtg run "${CONFIG_FILE}"
