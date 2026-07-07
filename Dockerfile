ARG BUILD_FROM
FROM $BUILD_FROM

# Копируем исполняемый файл mtg из официального образа
COPY --from=nineseconds/mtg:2 /mtg /usr/local/bin/mtg

# Копируем скрипт запуска
COPY run.sh /run.sh
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]