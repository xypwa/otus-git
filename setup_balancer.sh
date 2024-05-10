#!/bin/bash

ip_app_main=192.168.71.133;
#ip_app_rsrv=192.168.71.133;
#ip_db_master=192.168.71.133;
#ip_db_slave=192.168.71.133;
#ip_elk=192.168.71.133;

# создание сертификата
mkdir ~/certs && cd ~/certs;

#openssl genrsa -out localhost_rootCA.key 2048;
#openssl req -newkey rsa:2048 -nodes -keyout localhost_rootCA.key -out localhost_rootCA.csr < cert_pass_params.txt
#openssl x509 -signkey localhost_rootCA.key -in localhost_rootCA.csr -req -days 365 -out localhost_rootCA.crt;
openssl req -newkey rsa:2048 -nodes -keyout localhost_rootCA.key -x509 -days 365 -out localhost_rootCA.crt < cert_pass_params.txt
#где pass.txt содержит значения для read команд программы


#
# настройка авторизации по ключу
#
cd ~/.ssh;
echo 'qwertyzxv' > pass.txt
## для app-main
ssh-keygen -t rsa -f app_main -N ''
ssh-keygen -t rsa -f app_rsrv -N ''
ssh-keygen -t rsa -f db_master -N ''
ssh-keygen -t rsa -f db_slave -N ''
ssh-keygen -t rsa -f elk -N ''

#
# закидываем ключи на узлы
#
sshpass -f pass.txt ssh-copy-id -i app_main xypwa@$ip_app_main;
#sshpass -f pass.txt ssh-copy-id -i app_rsrv xypwa@$ip_app_rsrv;
#sshpass -f pass.txt ssh-copy-id -i db_master xypwa@$ip_db_master;
#sshpass -f pass.txt ssh-copy-id -i db_slave xypwa@$ip_db_slave;
#sshpass -f pass.txt ssh-copy-id -i elk xypwa@$ip_elk;

#rsync -e "ssh -i /root/.ssh/app_rsrv" /root/certs/* xypwa@192.168.71.133:/home/xypwa/
