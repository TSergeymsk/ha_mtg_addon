# Используем официальный базовый образ Home Assistant
FROM ghcr.io/home-assistant/base:latest

# Копируем исполняемый файл mtg из официального образа проекта
COPY --from=nineseconds/mtg:2 /mtg /usr/local/bin/mtg

# Копируем и делаем исполняемым скрипт запуска
COPY run.sh /run.sh
RUN chmod a+x /run.sh

# Добавляем метки для идентификации аддона
LABEL \
    io.hass.version="1.0.0" \
    io.hass.type="addon" \
    io.hass.arch="armhf|armv7|aarch64|amd64|i386"

# Запускаем скрипт
CMD [ "/run.sh" ]
