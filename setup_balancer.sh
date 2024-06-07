#!/bin/bash

REPO_DIR='/root/otus-git';


ip_app_node_1="192.168.71.140";
branch_app_node_1="app-node-1";
ip_app_node_2="192.168.71.143";
branch_app_node_2="app-node-2";
ip_db_master="192.168.71.147";
branch_db_master="db_master";
ip_db_slave="192.168.71.148";
branch_db_slave="db_slave";
#ip_elk="192.168.71.133";


# через sudo su зашли под рутом
cd ~;
echo 'qwertyzxv' > pass.txt

#
# настройка авторизации по ключу
#
# сгенерируем общий ключ для всех хостов
ssh-keygen -t rsa -f ~/.ssh/general -N ''

# закинем список хостов в файл
#echo "$ip_app_node-1 $ip_app_node-2 $ip_db_master $ip_db_slave $ip_elk" > ~/my_hosts.txt
#echo "$ip_app_node_1 $branch_app_node_1" > my_hosts.txt;
#echo "$ip_app_node_2 " >> my_hosts.txt
echo "$ip_db_master $branch_db_master" >> my_hosts.txt
echo "$ip_db_slave $branch_db_slave" >> my_hosts.txt
#echo "$ip_db_slave " >> my_hosts.txt
#echo "$ip_elk" >> my_hosts.txt

# закидываем ключи на узлы

while IFS=' ' read -r line || [[ -n "$line" ]]; do
    # Проверка непустой строки
    if [ -n "$line" ]; then
        # Извлечение имени и IP адреса из строки
        ip=$(echo "$line" | awk '{print $1}' )
        name=$(echo "$line" | awk '{print $2}' )
        if [ -n "$ip" ]; then
                echo "Sending ssh keys on ${ip}";
                sshpass -f ~/pass.txt ssh-copy-id -i ~/.ssh/general.pub "xypwa@$ip";
        fi;
        if [[ -n "$ip" && -n "$name" ]]; then
                echo "Downloading git branch ${name} into $REPO_DIR/$name";
                mkdir "$REPO_DIR/$name"; cd "$REPO_DIR/$name";
                git clone -b "$name" https://github.com/xypwa/otus-git.git;
                echo "Sending branch on ${ip}";
                rsync -avz -e "ssh -i ~/.ssh/general" ~/otus-git/"$name"/otus-git/* xypwa@"$ip":/home/xypwa/install
        fi;

    fi
done < ~/my_hosts.txt
#exit 1;

#
# настройка репликации БД
#
echo "Настройка репликации";
read -p 'Укажите Тип репликации. [1](default) GTID, [2] BINLOG POSITION: ' TYPE;
read -p 'Настроить TSL? (y/N)' TSL;

sshpass -f ~/pass.txt ssh -i ~/.ssh/general xypwa@"$ip_db_master" "echo qwertyzxv | sudo -S bash /home/xypwa/install/setup.sh ${TYPE} ${TSL}"
if [[ "$TYPE" -eq '2' ]]; then
    FILE=`ssh -i ~/.ssh/general xypwa@"$ip_db_master" cat /home/xypwa/binlog_file.output`;
    POSITION=`ssh -i ~/.ssh/general xypwa@"$ip_db_master" cat /home/xypwa/binlog_pos.output`;
    echo "$FILE";
    echo "$POSITION";

    if [[ "$TSL" -eq 'Y' || "$TSL" -eq 'y' ]]; then
    mkdir ~/tmp;
        rsync -avz -e "ssh -i ~/.ssh/general" xypwa@"$ip_db_master":/home/xypwa/certs/* ~/tmp/
        rsync -avz -e "ssh -i ~/.ssh/general" ~/tmp/* xypwa@"$ip_db_slave":/home/xypwa/install/
        sshpass -f ~/pass.txt ssh -i ~/.ssh/general xypwa@"$ip_db_slave" "echo qwertyzxv | sudo -S bash /home/xypwa/install/setup.sh ${TYPE} ${FILE} ${POSITION}";
    fi;
else
    sshpass -f ~/pass.txt ssh -i ~/.ssh/general xypwa@"$ip_db_slave" "echo qwertyzxv | sudo -S bash /home/xypwa/install/setup.sh ${TYPE}";
fi;
exit;

#
# настройка nginx
#
if [[ -e "$REPO_DIR/nginx/default" ]]; then
    cat "$REPO_DIR/nginx/default" | tee /etc/nginx/sites-available/default > /dev/null;
    sed -i "1i\upstream work_nodes {\n\tserver $ip_app_node_1:80;\n\tserver $ip_app_node_2:80;\n}\n" /etc/nginx/sites-available/default;
    #htpasswd -c /etc/nginx/conf.d/.htpasswd xypwa
fi;

if [[ -e "$REPO_DIR/nginx/manage" ]]; then
    # создание сертификата
    #mkdir ~/certs && cd ~/certs;

    NGINX_CERTS_DIR="/etc/nginx/certs/my";
    mkdir -p "$NGINX_CERTS_DIR";
#    openssl genrsa -out "$NGINX_CERTS_DIR/localhost_rootCA.key" 2048;
#    openssl req -newkey rsa:2048 -nodes -keyout "$NGINX_CERTS_DIR/localhost_rootCA.key" -out "$NGINX_CERTS_DIR/localhost_rootCA.csr" < ~/otus-git/cert_pass_params.txt
#    openssl x509 -signkey "$NGINX_CERTS_DIR/localhost_rootCA.key" -in "$NGINX_CERTS_DIR/localhost_rootCA.csr" -req -days 365 -out "$NGINX_CERTS_DIR/localhost_rootCA.crt";
    openssl req -newkey rsa:2048 -nodes -keyout "$NGINX_CERTS_DIR/localhost_rootCA.key" -x509 -days 365 -out "$NGINX_CERTS_DIR/localhost_rootCA.crt" < ~/otus-git/cert_pass_params.txt

    cat "$REPO_DIR/nginx/manage" | tee /etc/nginx/sites-available/manage > /dev/null;
    ln -sf /etc/nginx/sites-available/manage /etc/nginx/sites-enabled/manage;
fi;
