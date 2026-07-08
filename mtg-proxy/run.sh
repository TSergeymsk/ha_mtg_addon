#!/usr/bin/env bashio

# Директория для конфигурации
CONFIG_DIR="/config"
CONFIG_FILE="${CONFIG_DIR}/mtg.toml"

# Создаем директорию, если её нет
mkdir -p "${CONFIG_DIR}"

# Читаем содержимое поля 'config' из options.json
# и записываем его в файл конфигурации
bashio::config 'config' > "${CONFIG_FILE}"

# Проверяем, что файл не пустой
if [ ! -s "${CONFIG_FILE}" ]; then
    bashio::log.error "Конфигурационный файл пуст! Пожалуйста, заполните поле 'config'."
    exit 1
fi

# Запускаем mtg с указанным конфигурационным файлом
bashio::log.info "Запуск mtg с конфигурацией из ${CONFIG_FILE}"
exec /usr/local/bin/mtg run "${CONFIG_FILE}"
