#!/bin/sh
#
# mysql backup script
#

#DBDUMP_DEBUG
#DBDUMP_TYPE
#DBDUMP_HOST
#DBDUMP_DB
#DBDUMP_ALL_DB
#DBDUMP_PORT
#DBDUMP_USER
#DBDUMP_PASSWORD
#DBDUMP_OPTS

if [ "$DBDUMP_DEBUG" = true ] ; then
  set -ex
fi

if $DBDUMP_HOST ; then

BACKUP_DIR="/backup"
TIMESTAMP="$(date +%Y%m%d%H%M%S)"

echo "test mysql connection"
if [ -z "$(mysql -h ${MYSQL_HOST} -P ${MYSQL_PORT} -u ${MYSQL_USERNAME} -B -N -e 'SHOW DATABASES;')" ]; then
  echo "mysql connection failed! exiting..."
  exit 1
fi

echo "started" > ${BACKUP_DIR}/${TIMESTAMP}.state

echo "delete old backups"
find ${BACKUP_DIR} -maxdepth 2 -mtime +${KEEP_DAYS} -regex "^${BACKUP_DIR}/.*[0-9]*_.*\.sql\.gz$" -type f -exec rm {} \;

if $DBDUMP_DB && [[ "$DBDUMP_ALL_DATABASES" != "true" ]] ; then
  echo "Backing up single db ${MYSQL_DB}"
  mkdir -p "${BACKUP_DIR}"/"${MYSQL_DB}"
  mysqldump ${MYSQL_OPTS} -h ${MYSQL_HOST} -P ${MYSQL_PORT} -u ${MYSQL_USERNAME} --databases ${MYSQL_DB} | gzip > ${BACKUP_DIR}/${MYSQL_DB}/${TIMESTAMP}_${MYSQL_DB}.sql.gz
  rc=$?

elif [ "$DBDUMP_ALL_DATABASES" = "true" ]

  for MYSQL_DB in $(mysql -h "${MYSQL_HOST}" -P ${MYSQL_PORT} -u ${MYSQL_USERNAME} -B -N -e "SHOW DATABASES;"|egrep -v '^(information|performance)_schema$'); do
    echo "Backing up db ${MYSQL_DB}"
    mkdir -p "${BACKUP_DIR}"/"${MYSQL_DB}"
    mysqldump ${MYSQL_OPTS} -h ${MYSQL_HOST} -P ${MYSQL_PORT} -u ${MYSQL_USERNAME} --databases ${MYSQL_DB} | gzip > ${BACKUP_DIR}/${MYSQL_DB}/${TIMESTAMP}_${MYSQL_DB}.sql.gz
    rc=$?
  done
fi

if [ "$DBDUMP_DEBUG" = true ] ; then
  echo Contents of ${BACKUP_DIR}
  ls -lahR ${BACKUP_DIR}
fi

if [ "$rc" != "0" ]; then
  echo "backup failed"
  exit 1
fi

echo "complete" > ${BACKUP_DIR}/${TIMESTAMP}.state

echo "Disk usage in ${BACKUP_DIR}"
du -h -d 2 ${BACKUP_DIR}

echo "Backup successful! :-)"
else
  echo "no mysql.host set in values file... nothing to do... exiting :)"
fi
