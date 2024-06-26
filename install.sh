#!/bin/bash

CONF_PATH="/home/xypwa/install/conf.d";
INCLUDE_NGINX=$1;
CONF_NGINX_PATH="${CONF_PATH}/logstash-nginx.conf";
INCLUDE_APACHE=$2;
CONF_APACHE_PATH="${CONF_PATH}/logstash-apache.conf";
INCLUDE_MYSQL=$3;
CONF_MYSQL_PATH="${CONF_PATH}/logstash-mysql.conf";

if ! [ -d /etc/logstash/conf.d ]; then
  mkdir /etc/logstash/conf.d;
fi;

if [[ "$INCLUDE_NGINX" = "Y" || "$INCLUDE_NGINX" = "y" ]]; then
  cp "${CONF_NGINX_PATH} /etc/logstash/conf.d";
fi;
if [[ "$INCLUDE_APACHE" = "Y" || "$INCLUDE_APACHE" = "y" ]]; then
  cp "${CONF_APACHE_PATH} /etc/logstash/conf.d";
fi;
if [[ "$INCLUDE_MYSQL" = "Y" || "$INCLUDE_MYSQL" = "y" ]]; then
  cp "${CONF_MYSQL_PATH} /etc/logstash/conf.d";
fi;


systemctl restart logstash;
