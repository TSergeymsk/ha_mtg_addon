#!/usr/bin/env bashio

CONFIG_DIR="/config"
CONFIG_FILE="${CONFIG_DIR}/mtg.toml"

mkdir -p "${CONFIG_DIR}"

# Конвертируем options.json в TOML с помощью yq
python3 -m yq -o toml . < /data/options.json > "${CONFIG_FILE}"

if [ ! -s "${CONFIG_FILE}" ]; then
    bashio::log.error "Не удалось сгенерировать конфигурационный файл."
    exit 1
fi

bashio::log.info "Конфигурация сохранена в ${CONFIG_FILE}"
bashio::log.info "Запуск mtg..."
exec /usr/local/bin/mtg run "${CONFIG_FILE}"
