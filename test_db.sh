#!/bin/bash

REPO_DIR='/root/otus-git';

ip_db_master="192.168.71.147";
branch_db_master="db_master";
ip_db_slave="192.168.71.148";
branch_db_slave="db_slave";


#exit 1;

#
# настройка репликации БД
#
echo "Настройка репликации";
TYPE=`read -p 'Укажите Тип репликации. [1](default) GTID, [2] BINLOG POSITION'`;
echo "$TYPE";
sshpass -f ~/pass.txt ssh -i ~/.ssh/ganeral xypwa@"$ip_db_master" "sudo bash /home/xypwa/install/install.sh ${TYPE}"
sshpass -f ~/pass.txt ssh -i ~/.ssh/ganeral xypwa@"$ip_db_slave" "sudo bash /home/xypwa/install/install.sh ${TYPE}"
