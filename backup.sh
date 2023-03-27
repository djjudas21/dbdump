#!/bin/sh
#
# database backup script

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

if [ "$DBDUMP_HOST" ] ; then

  BACKUP_DIR="/backup"
  TIMESTAMP="$(date +%Y%m%d%H%M%S)"

  echo "started" > ${BACKUP_DIR}/"${TIMESTAMP}".state

  echo "delete old backups"
  find ${BACKUP_DIR} -maxdepth 2 -mtime +"${KEEP_DAYS}" -regex "^${BACKUP_DIR}/.*[0-9]*_.*\.sql\.gz$" -type f -exec rm {} \;

  case $DBDUMP_TYPE in

    mysql)
      echo "test mysql connection"
      if [ -z "$(mysql -h "${DBDUMP_HOST}" -P "${DBDUMP_PORT}" -u "${DBDUMP_USER}" -p"${DBDUMP_PASSWORD}" -B -N -e 'SHOW DATABASES;')" ]; then
        echo "mysql connection failed! exiting..."
        exit 1
      fi    

      if $DBDUMP_DB && [ "$DBDUMP_ALL_DATABASES" != "true" ] ; then
        echo "Backing up single db ${DBDUMP_DB}"
        mkdir -p "${BACKUP_DIR}"/"${DBDUMP_DB}"
        mysqldump "${DBDUMP_OPTS}" -h "${DBDUMP_HOST}" -P "${DBDUMP_PORT}" -u "${DBDUMP_USER}" -p"${DBDUMP_PASSWORD}" --databases "${DBDUMP_DB}" | gzip > "${BACKUP_DIR}"/"${DBDUMP_DB}"/"${TIMESTAMP}"_"${DBDUMP_DB}".sql.gz
        rc=$?
      elif [ "$DBDUMP_ALL_DATABASES" = "true" ]; then
        for DBDUMP_DB in $(mysql -h "${DBDUMP_HOST}" -P "${DBDUMP_PORT}" -u "${DBDUMP_USER}" -B -N -e "SHOW DATABASES;"|grep -E -v '^(information|performance)_schema$'); do
          echo "Backing up db ${DBDUMP_DB}"
          mkdir -p "${BACKUP_DIR}"/"${DBDUMP_DB}"
          mysqldump "${DBDUMP_OPTS}" -h "${DBDUMP_HOST}" -P "${DBDUMP_PORT}" -u "${DBDUMP_USER}" -p"${DBDUMP_PASSWORD}" --databases "${DBDUMP_DB}" | gzip > "${BACKUP_DIR}"/"${DBDUMP_DB}"/"${TIMESTAMP}"_"${DBDUMP_DB}".sql.gz
          rc=$?
        done
      fi
      ;;

    postgresql)
      echo "test postgresql connection"
      if [ -z "$(PGPASSWORD="$DBDUMP_PASSWORD" psql -h "${DBDUMP_HOST}" -U "${DBDUMP_USER}" -d "${DBDUMP_DB}" -c '\l')" ]; then
        echo "postgres connection failed! exiting..."
        exit 1
      fi

      if [ "$DBDUMP_DB" ] && [ "$DBDUMP_ALL_DATABASES" != "true" ] ; then
        echo "Backing up single db ${DBDUMP_DB}"
        mkdir -p "${BACKUP_DIR}"/"${DBDUMP_DB}"
        PGPASSWORD="$DBDUMP_PASSWORD" pg_dump -h "${DBDUMP_HOST}" -p "${DBDUMP_PORT}" -U "${DBDUMP_USER}" -d "${DBDUMP_DB}" | gzip > "${BACKUP_DIR}"/"${DBDUMP_DB}"/"${TIMESTAMP}"_"${DBDUMP_DB}".sql.gz
        rc=$?
      elif [ "$DBDUMP_ALL_DATABASES" = "true" ] ; then
        for DBDUMP_DB in $(mysql -h "${DBDUMP_HOST}" -P "${DBDUMP_PORT}" -u "${DBDUMP_USER}" -B -N -e "SHOW DATABASES;"|grep -E -v '^(information|performance)_schema$'); do
          echo "Backing up db ${DBDUMP_DB}"
          mkdir -p "${BACKUP_DIR}"/"${DBDUMP_DB}"
          PGPASSWORD="$DBDUMP_PASSWORD" pg_dump -h "${DBDUMP_HOST}" -p "${DBDUMP_PORT}" -U "${DBDUMP_USER}" -d "${DBDUMP_DB}" | gzip > "${BACKUP_DIR}"/"${DBDUMP_DB}"/"${TIMESTAMP}"_"${DBDUMP_DB}".sql.gz
          rc=$?
        done
      fi
      ;;

    *)
      echo "must set database type"
      ;;
  esac

  if [ "$rc" != "0" ]; then
    echo "backup failed"
    exit 1
  fi

  if [ "$DBDUMP_DEBUG" = true ] ; then
    echo Contents of ${BACKUP_DIR}
    ls -lahR ${BACKUP_DIR}
  fi

  echo "complete" > ${BACKUP_DIR}/"${TIMESTAMP}".state

  echo "Disk usage in ${BACKUP_DIR}"
  du -h -d 2 ${BACKUP_DIR}

  echo "Backup successful! :-)"
else
  echo "no DB host set in values file... nothing to do... exiting :)"
fi
