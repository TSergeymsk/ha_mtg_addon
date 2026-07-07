#!/usr/bin/env bashio

set -e

# Читаем настройки
DEBUG=$(bashio::config 'debug')
SECRET=$(bashio::config 'secret')
BIND=$(bashio::config 'bind')
PREFER_IP=$(bashio::config 'prefer_ip')
PROXIES=$(bashio::config 'proxies')

# Проверяем обязательный секрет
if [ -z "$SECRET" ]; then
    bashio::log.error "Секрет не задан! Сгенерируйте его и укажите в настройках."
    exit 1
fi

bashio::log.info "Генерация конфигурационного файла /data/mtg.toml"

# Формируем конфиг
cat > /data/mtg.toml <<EOF
[mtproxy]
secret = "$SECRET"
bind = "$BIND"
prefer-ip = "$PREFER_IP"
debug = $DEBUG
EOF

# Добавляем секцию proxies, если она не пуста
if [ -n "$PROXIES" ]; then
    echo "proxies = $PROXIES" >> /data/mtg.toml
fi

# Добавляем стандартные настройки Telegram (можно не менять)
cat >> /data/mtg.toml <<EOF

[telegram]
# Используются встроенные серверы по умолчанию
EOF

bashio::log.info "Запуск mtg с конфигом /data/mtg.toml"
exec mtg /data/mtg.toml