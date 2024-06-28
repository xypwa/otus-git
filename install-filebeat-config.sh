#!/bin/bash

if [[ -d /etc/filebeat && -f /home/xypwa/install/filebeat.yml ]]; then
  cp -f /home/xypwa/install/filebeat.yml /etc/filebeat/
fi;
systemctl restart filebeat;
