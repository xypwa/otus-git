#!/bin/bash


date_str=$(date +%Y.%m_%H:%M);
echo "Run script ${date_str}" >> /home/xypwa/lg.lg;
dump_dir=/home/xypwa/dumps/$date_str

mkdir -p $dump_dir;

for table in $(mysql -e "use majordomo; show tables" -s --skip-column-names ); do
        mysqldump --set-gtid-purged=OFF majordomo $table > "${dump_dir}/${table}.sql"
done
