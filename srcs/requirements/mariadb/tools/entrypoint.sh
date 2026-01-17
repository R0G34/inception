#!/bin/bash
set -e

echo ">> MariaDB entrypoint running"

chown -R mysql:mysql /var/lib/mysql
chown -R mysql:mysql /run/mysqld

if [ ! -d "/var/lib/mysql/${MYSQL_DATABASE}" ]; then
	echo "Initializating MariaDB and user"

	mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null

	mysqld --user=mysql --datadir=/var/lib/mysql --skip-networking &
	pid="$!"

	until mysqladmin ping --silent; do
		sleep 1
	done

	mysql -u root <<EOSQL
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOSQL

	mysqladmin -u root shutdown
	wait "$pid"
	echo "MariaDB initialized."
fi

exec "$@"
