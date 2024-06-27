#!/bin/bash

if [[ -d /etc/filebeat && -f ~/otus-git/filebeat.yml ]]; then
  cp -f ~/otus-git/filebeat.yml /etc/filebeat/
fi;
