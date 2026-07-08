FROM ghcr.io/home-assistant/base:latest

COPY --from=nineseconds/mtg:2 /mtg /usr/local/bin/mtg

# Устанавливаем yq (конвертер JSON -> TOML)
RUN apk add --no-cache py3-pip && pip3 install yq

COPY run.sh /run.sh
RUN chmod a+x /run.sh

LABEL \
    io.hass.version="1.0.0" \
    io.hass.type="addon" \
    io.hass.arch="armhf|armv7|aarch64|amd64|i386"

CMD [ "/run.sh" ]
