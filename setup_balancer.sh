#!/bin/bash

REPO_DIR='/root/otus-git';
# Пропускаем проверку незнакомых хостов при ssh подключении #
echo -e "    UserKnownHostsFile /dev/null\n    StrictHostKeyChecking no" >> /etc/ssh/ssh_config;

ip_app_node_1="192.168.71.140";
branch_app_node_1="app-node-1";
ip_app_node_2="192.168.71.143";
branch_app_node_2="app-node-2";
ip_db_master="192.168.71.147";
branch_db_master="db_master";
#ip_db_slave="192.168.71.133";
#slave_db_master="db_master";
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
echo "$ip_app_node_1 $branch_app_node_1\n" > my_hosts.txt;
echo "$ip_app_node_2 " >> my_hosts.txt
echo "$ip_db_master $branch_db_master\n" >> my_hosts.txt
#echo "$ip_db_slave " >> my_hosts.txt
#echo "$ip_elk" >> my_hosts.txt

# закидываем ключи на узлы
for line in `cat ~/my_hosts.txt`; do
    arr=($line);
    if [ ${arr[0]} ]; then
        sshpass -f ~/pass.txt ssh-copy-id -i ~/.ssh/general.pub "${arr[0]}";
    fi;
    if [ ${arr[1]} ]; then
        git clone -b "${arr[1]} --single-branch https://github.com/xypwa/otis-git.git";
        rsync -avz  "~/${arr[1]} xypwa@${arr[0]}":/home/xypwa/install
    fi;
done

exit 1;


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
