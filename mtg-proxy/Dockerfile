# Используем явный базовый образ вместо ARG BUILD_FROM
FROM ghcr.io/home-assistant/base:latest

# Копируем исполняемый файл mtg из официального образа
COPY --from=nineseconds/mtg:2 /mtg /usr/local/bin/mtg

# Копируем скрипт запуска
COPY run.sh /run.sh
RUN chmod a+x /run.sh

# Добавляем необходимые метки
LABEL \
    io.hass.version="1.0.0" \
    io.hass.type="addon" \
    io.hass.arch="armhf|armv7|aarch64|amd64|i386"

CMD [ "/run.sh" ]
