#!/bin/bash

TYPE=$1;
BKP=$2;
DB_MASTER="192.168.71.147";
DB_NAME='majordomo';

service mysql stop;

CONF_BINLOG="
server-id = 2
log-bin = mysql-bin
relay-log = relay-log-server
binlog_do_db = majordomo
read-only = ON
"
CONF_GTID="
server-id = 2
log-bin = mysql-bin
relay-log = relay-log-server
binlog_do_db = majordomo
gtid-mode=ON
enforce-gtid-consistency
log-replica-updates
read-only = ON
"

CERTS=`find /home/xypwa/install/ -type f -name "*.pem" | wc -l`


if [[ "$TYPE" -eq '2' ]]; then
  echo "$CONF_BINLOG" >> /etc/mysql/mysql.conf.d/mysqld.cnf;
  service mysql start;
  FILE=$3; POSITION=$4;
  mysql -uroot <<EOF
CREATE DATABASE ${DB_NAME};
CHANGE REPLICATION SOURCE TO
SOURCE_HOST = "${DB_MASTER}",
SOURCE_USER = 'replicant',
SOURCE_PASSWORD = 'qwertyzxv',
SOURCE_LOG_FILE="${FILE}",
SOURCE_LOG_POS=${POSITION},
GET_SOURCE_PUBLIC_KEY = 1;
EOF
else
  echo "$CONF_GTID" >> /etc/mysql/mysql.conf.d/mysqld.cnf;
  service mysql start;
  mysql -uroot <<EOF
CREATE DATABASE ${DB_NAME};
CHANGE REPLICATION SOURCE TO
SOURCE_HOST = "${DB_MASTER}",
SOURCE_USER = 'replicant',
SOURCE_PASSWORD = 'qwertyzxv',
SOURCE_AUTO_POSITION = 1,
GET_SOURCE_PUBLIC_KEY = 1;
EOF
fi;


if [[ "${BKP}" -eq "2" && -f /home/xypwa/install/work_dump.sql ]]; then
  mysql -u root majordomo < /home/xypwa/install/work_dump.sql;
elif [ -f /home/xypwa/install/default_dump.sql ]; then
  mysql -u root majordomo < /home/xypwa/install/default_dump.sql;
else
  echo 'Backup file is missing!';
  exit 1;
fi;

if [[ "$CERTS" -gt 0 ]]; then
  cp -f ./*.pem /var/lib/mysql;
  chown mysql:mysql /var/lib/mysql -R;
    mysql -uroot <<EOF
CHANGE REPLICATION SOURCE TO 
SOURCE_SSL_CA = "ca.pem", 
SOURCE_SSL_CERT = "server-cert.pem", 
SOURCE_SSL_KEY = "server-key.pem", 
SOURCE_SSL=1;
EOF
fi;

# service mysql restart;
mysql -u root -e "START REPLICA;"
mysql -u root -e "SHOW REPLICA STATUS\G"
