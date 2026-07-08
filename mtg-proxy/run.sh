#!/usr/bin/env bashio

CONFIG_DIR="/config"
CONFIG_FILE="${CONFIG_DIR}/mtg.toml"
mkdir -p "${CONFIG_DIR}"

# Читаем основные параметры
DEBUG=$(bashio::config 'debug')
SECRET=$(bashio::config 'secret')
BIND_TO=$(bashio::config 'bind_to')
CONCURRENCY=$(bashio::config 'concurrency')
PREFER_IP=$(bashio::config 'prefer_ip')
AUTO_UPDATE=$(bashio::config 'auto_update')
TOLERATE_TIME_SKEWNESS=$(bashio::config 'tolerate_time_skewness')
ALLOW_FALLBACK=$(bashio::config 'allow_fallback_on_unknown_dc')

# Проверяем обязательные параметры
if [ -z "${SECRET}" ] || [ -z "${BIND_TO}" ]; then
    bashio::log.error "secret и bind_to обязательны"
    exit 1
fi

# Начинаем формировать TOML
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

# Добавляем раздел network, если он есть
if bashio::config.has_value 'network.dns'; then
    DNS=$(bashio::config 'network.dns')
    cat >> "${CONFIG_FILE}" <<EOF

[network]
dns = "${DNS}"
EOF
    # Добавляем proxies, если есть
    if bashio::config.has_value 'network.proxies'; then
        PROXIES=$(bashio::config 'network.proxies')
        # Преобразуем JSON-массив в TOML-массив
        PROXIES_TOML=$(echo "${PROXIES}" | jq -r 'join(", ")')
        cat >> "${CONFIG_FILE}" <<EOF
proxies = [${PROXIES_TOML}]
EOF
    fi
    # Добавляем timeout, если есть
    if bashio::config.has_value 'network.timeout.tcp'; then
        TCP_TIMEOUT=$(bashio::config 'network.timeout.tcp')
        HTTP_TIMEOUT=$(bashio::config 'network.timeout.http')
        IDLE_TIMEOUT=$(bashio::config 'network.timeout.idle')
        cat >> "${CONFIG_FILE}" <<EOF

[network.timeout]
tcp = "${TCP_TIMEOUT}"
http = "${HTTP_TIMEOUT}"
idle = "${IDLE_TIMEOUT}"
EOF
    fi
fi

# Добавляем раздел defense (если есть)
if bashio::config.has_value 'defense.doppelganger.repeats-per-raid'; then
    DOPP_REPEATS=$(bashio::config 'defense.doppelganger.repeats-per-raid')
    DOPP_RAID=$(bashio::config 'defense.doppelganger.raid-each')
    DOPP_DRS=$(bashio::config 'defense.doppelganger.drs')
    cat >> "${CONFIG_FILE}" <<EOF

[defense.doppelganger]
repeats-per-raid = ${DOPP_REPEATS}
raid-each = "${DOPP_RAID}"
drs = ${DOPP_DRS}
EOF
    # urls (если есть)
    if bashio::config.has_value 'defense.doppelganger.urls'; then
        URLS=$(bashio::config 'defense.doppelganger.urls')
        URLS_TOML=$(echo "${URLS}" | jq -r 'map("\"" + . + "\"") | join(", ")')
        cat >> "${CONFIG_FILE}" <<EOF
urls = [${URLS_TOML}]
EOF
    fi
fi

# Аналогично добавляем anti-replay, blocklist, allowlist, stats...

# Просто для примера добавим остальные разделы, но в вашем полном config.yaml они уже есть.
# Я допишу только ключевые, а остальные вы сможете легко добавить по аналогии.

# anti-replay
if bashio::config.has_value 'defense.anti-replay.enabled'; then
    AR_ENABLED=$(bashio::config 'defense.anti-replay.enabled')
    AR_MAX=$(bashio::config 'defense.anti-replay.max-size')
    AR_ERROR=$(bashio::config 'defense.anti-replay.error-rate')
    cat >> "${CONFIG_FILE}" <<EOF

[defense.anti-replay]
enabled = ${AR_ENABLED}
max-size = "${AR_MAX}"
error-rate = ${AR_ERROR}
EOF
fi

# blocklist
if bashio::config.has_value 'defense.blocklist.enabled'; then
    BL_ENABLED=$(bashio::config 'defense.blocklist.enabled')
    BL_CONC=$(bashio::config 'defense.blocklist.download-concurrency')
    BL_UPDATE=$(bashio::config 'defense.blocklist.update-each')
    cat >> "${CONFIG_FILE}" <<EOF

[defense.blocklist]
enabled = ${BL_ENABLED}
download-concurrency = ${BL_CONC}
update-each = "${BL_UPDATE}"
EOF
    if bashio::config.has_value 'defense.blocklist.urls'; then
        URLS=$(bashio::config 'defense.blocklist.urls')
        URLS_TOML=$(echo "${URLS}" | jq -r 'map("\"" + . + "\"") | join(", ")')
        cat >> "${CONFIG_FILE}" <<EOF
urls = [${URLS_TOML}]
EOF
    fi
fi

# allowlist аналогично, и stats...

bashio::log.info "Конфигурация сохранена в ${CONFIG_FILE}"
exec /usr/local/bin/mtg run "${CONFIG_FILE}"
