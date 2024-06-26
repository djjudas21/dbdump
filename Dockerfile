FROM alpine:3.19

RUN apk add --update-cache \
    mysql-client \
    postgresql-client \
  && rm -rf /var/cache/apk/*

COPY dbdump.sh /

ENTRYPOINT ["/bin/ash", "/dbdump.sh"]
