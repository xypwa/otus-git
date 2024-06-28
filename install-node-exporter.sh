#!/bin/bash

NODE_EXPORTER_CONF="
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
"
MYSQL_EXPORTER_CONF="
[Unit]
Description=MySQL Exporter

[Service]
User=mysql_exporter
Type=simple
Restart=always
ExecStart=/usr/local/bin/mysqld_exporter 
--config.my-cnf /etc/.exporter.cnf 
--collect.auto_increment.columns 
--collect.binlog_size 
--collect.engine_innodb_status 
--collect.engine_tokudb_status 
--collect.global_status 
[Install]
WantedBy=multi-user.target
"


if ! [[ -f /usr/local/bin/node_exporter ]]; then 
  useradd -U --no-create-home --shell /bin/false node_exporter
  cp /home/xypwa/node_exporter-*.linux-amd64/node_exporter /usr/local/bin
  if [[ "$?" -eq 0 ]]; then
    chown node_exporter /usr/local/bin/node_exporter;
    chgrp node_exporter /usr/local/bin/node_exporter;
    echo "${NODE_EXPORTER_CONF}" > /etc/systemd/system/node_exporter.service
  else
    echo "Problem due copy";
  fi;
fi;
if ! [[ -f /usr/local/bin/mysql_exporter ]]; then 
  useradd -U --no-create-home --shell /bin/false mysql_exporter
  cp /home/xypwa/mysql_exporter-*.linux-amd64/mysql_exporter /usr/local/bin
  if [[ "$?" -eq 0 ]]; then
    chown mysql_exporter /usr/local/bin/mysql_exporter;
    chgrp mysql_exporter /usr/local/bin/mysql_exporter;
    mysql -u root -e "CREATE USER 'exporter'@'localhost' IDENTIFIED BY 'password' WITH MAX_USER_CONNECTIONS 3;"
    mysql -u root -e "GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO 'exporter'@'localhost';"
    echo "
[client]
user=exporter
password=password
" > /etc/.exporter.cnf
  echo "${MYSQL_EXPORTER_CONF}" > /etc/systemd/system/mysql_exporter.service
  else
    echo "Problem due copy";
  fi;
fi;

systemctl daemon-reload
systemctl start node_exporter
systemctl status node_exporter
systemctl enable node_exporter
