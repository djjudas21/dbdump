FROM alpine

RUN apk add --update-cache \
    mysql-client \
    postgresql-client \
  && rm -rf /var/cache/apk/*

COPY backup.sh /
