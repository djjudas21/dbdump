# dbdump

Universal database backup script for MySQL/MariaDB and PostgreSQL.

This is intended to be run in Kubernetes via the [Helm chart](https://github.com/djjudas21/charts)

dbdump accepts the following arguments, set as environment variables.

| Argument          | Meaning                      | Example                              |
|-------------------|------------------------------|--------------------------------------|
| `DBDUMP_DEBUG`    | Enable debug output          | `true` or `false`                    |
| `DBDUMP_TYPE`     | Database engine              | `mysql` or `postgresql`              |
| `DBDUMP_HOST`     | Hostname of database server  | `mysql.example.com` or `192.168.1.1` |
| `DBDUMP_DB`       | Database schema to back up   | `mydata`                             |
| `DBDUMP_ALL_DB`   | Enable backup of all schemas | `true` or `false`                    |
| `DBDUMP_PORT`     | TCP port of database server  | `3306` or `5432`                     |
| `DBDUMP_USER`     | Username for database server | `root` or `postgres`                 |
| `DBDUMP_PASSWORD` | Password for database server | `pAsSwOrD`                           |
| `DBDUMP_OPTS`     | Extra options for dump       |                                      |
