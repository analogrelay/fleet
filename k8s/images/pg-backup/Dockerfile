FROM postgres:16.1

RUN mkdir /app
WORKDIR /app

COPY ./backup.sh /app/backup.sh

ENTRYPOINT [ "/app/backup.sh" ]