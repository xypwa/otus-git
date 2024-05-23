#!/bin/bash



# Пропускаем проверку незнакомых хостов при ssh подключении #
echo "    UserKnownHostsFile /dev/null\n    StrictHostKeyChecking no" >> /etc/ssh/ssh_config;
user=`whoami`;
ip_app_node-1=192.168.71.140;
#ip_app_node-2=192.168.71.143;
#ip_db_master=192.168.71.133;
#ip_db_slave=192.168.71.133;
#ip_elk=192.168.71.133;


#
# настройка авторизации по ключу
#

echo 'qwertyzxv' > pass.txt
cat pass.txt | sudo -S su 
cd ~;
mv "/home/$user/pass.txt" /root;


# сгенерируем общий ключ для всех хостов
ssh-keygen -t rsa -f general -N ''

# закинем список хостов в файл
#echo "$ip_app_node-1 $ip_app_node-2 $ip_db_master $ip_db_slave $ip_elk" > ~/my_hosts.txt
echo "$ip_app_node-1" > my_hosts.txt

# закидываем ключи на узлы
for ip in `cat ~/my_hosts.txt`; do
    sshpass -f ~/pass.txt ssh-copy-id -i ~/.ssh/general.pub $ip
done

#sshpass -f pass.txt ssh-copy-id -i app_main xypwa@$ip_app_main;
#sshpass -f pass.txt ssh-copy-id -i app_rsrv xypwa@$ip_app_rsrv;
#sshpass -f pass.txt ssh-copy-id -i db_master xypwa@$ip_db_master;
#sshpass -f pass.txt ssh-copy-id -i db_slave xypwa@$ip_db_slave;
#sshpass -f pass.txt ssh-copy-id -i elk xypwa@$ip_elk;

#rsync -e "ssh -i /root/.ssh/app_rsrv" /root/certs/* xypwa@192.168.71.133:/home/xypwa/

#
# настройка nginx 
#
if [[ -e /home/xypwa/restore/nginx/default ]] then;
    cat /home/xypwa/restore/nginx/default > /etc/nginx/sites-avaliable/default;
    sed -i "1i\upstream work_nodes {\n\tserver $ip_app_node-1:80;\n\tserver $ip_app_node-2:80;\n}\n";
    #htpasswd -c /etc/nginx/conf.d/.htpasswd xypwa
fi;

if [[ -e /home/xypwa/restore/nginx/manage ]] then;
    # создание сертификата
    #mkdir ~/certs && cd ~/certs;
    
    #openssl genrsa -out localhost_rootCA.key 2048;
    #openssl req -newkey rsa:2048 -nodes -keyout localhost_rootCA.key -out localhost_rootCA.csr < cert_pass_params.txt
    #openssl x509 -signkey localhost_rootCA.key -in localhost_rootCA.csr -req -days 365 -out localhost_rootCA.crt;
    #openssl req -newkey rsa:2048 -nodes -keyout localhost_rootCA.key -x509 -days 365 -out localhost_rootCA.crt < cert_pass_params.txt

    cat /home/xypwa/restore/nginx/manage /etc/nginx/sites-available/manage;
    ln -sf /etc/nginx/sites-available/manage /etc/nginx/sites-enabled/manage;
fi;    
