FROM postgres:16.1

RUN apt-get -qqy update && \
  apt-get -qqy install curl uuid-runtime && \
  rm -rf /var/lib/apt/lists/*

RUN mkdir /app
WORKDIR /app

COPY ./backup.sh /app/backup.sh
COPY ./restore.sh /app/restore.sh

ENTRYPOINT [ "/app/backup.sh" ]