#!/bin/sh

# pw groupmod wheel -m vagrant

# pw adduser -n judge -s /bin/sh -c judge
# pw usermod judge -G wheel

# mkdir -p /home/judge/.ssh
# fetch https://nasa.cs.nycu.edu.tw/sa/2023/nasakey.pub
# rm /home/judge/.ssh/authorized_keys
# cat nasakey.pub >> /home/judge/.ssh/authorized_keys

# freebsd-update fetch install
# pkg update
# pkg install -y wireguard-tools-1.0.20210914_3
# pkg install -y yq

# mkdir -p /usr/local/etc/wireguard
# cp /vagrant/wg0.conf /usr/local/etc/wireguard/wg0.conf
# wg-quick up /usr/local/etc/wireguard/wg0.conf

# echo HW1 setting up successfully

# cp /vagrant/hw2.sh /home/judge/hw2.sh
# chmod +x /home/judge/hw2.sh
# chmod -R 777 /tmp

# ========================================
usermod -aG sudo vagrant
usermod -aG docker vagrant

default_shell="/bin/sh"

username="judge"

useradd -m -s "$default_shell" "$username"

# Set password for the specified user
# echo "$username:password" | chpasswd

# Allow passwordless sudo for the specified user
usermod -aG sudo judge
usermod -a -G docker judge

echo '# Allow passwordless sudo for the specified user
judge ALL=(ALL) NOPASSWD: ALL' | visudo -cf -

mkdir -p /home/judge/.ssh
curl https://nasa.cs.nycu.edu.tw/sa/2023/nasakey.pub >> /home/judge/.ssh/authorized_keys

# install wireguard
apt-get update
apt-get install -y wireguard jq net-tools apache2-utils fail2ban
snap install yq

mkdir -p /usr/local/etc/wireguard
cp /vagrant/wg0.conf /usr/local/etc/wireguard/wg0.conf
wg-quick up /usr/local/etc/wireguard/wg0.conf

echo HW1 setting up successfully

cp /vagrant/hw2.sh /home/judge/hw2.sh
chmod +x /home/judge/hw2.sh
chmod 777 /tmp

# hw3 setup
# groupadd -g 2001 sftp
# groupadd -g 2002 sftp-readonly
# useradd -u 2000 sysadm
# usermod -aG sudo sysadm

# mkdir -p /home/sysadm/.ssh
# curl https://nasa.cs.nycu.edu.tw/sa/2023/nasakey.pub >> /home/sysadm/.ssh/authorized_keys
# mkdir -p /home/sftp/public
# mkdir -p /home/sftp/hidden/treasure
# echo 123 > /home/sftp/hidden/treasure/secret

# # sftp-u1, sftp-u2
# # /home/sftp/public READ EXEC
# # /home/sftp/public/* READ WRITE EXEC
# # /home/sftp/hidden WRITE EXEC
# # /home/sftp/hidden/treasure READ EXEC
# # /home/sftp/hidden/treasure/secret READ

# # anonymous
# # /home/sftp/public READ EXEC
# # /home/sftp/public/* READ
# # /home/sftp/hidden WRITE EXEC
# # /home/sftp/hidden/treasure READ EXEC
# # /home/sftp/hidden/treasure/secret READ
# chown -R :sftp /home/sftp/public
# chown -R :sftp /home/sftp/hidden
# chmod -R 755 /home/sftp/public
# chmod -R 774 /home/sftp/hidden
# chmod -R 555 /home/sftp/hidden/treasure

# hw4 setup
mkdir -p /home/judge/log
# apt install nginx -y

mkdir -p /home/judge/www/67.cs.nycu
mkdir -p /home/judge/www/10.113.67.11

mkdir -p /etc/nginx/ssl

cp /vagrant/nginx/judge-rotate.conf /home/judge/log/judge-rotate.conf-CRLF
# cp -r /vagrant/nginx/nginx.conf /etc/nginx/nginx.conf
cp -r /vagrant/nginx/htmls/* /home/judge/www
cp -r /vagrant/nginx/conf.d/ /etc/nginx


echo "101136711" | htpasswd -c -i /etc/nginx/conf.d/password sa-admin

tr -d '\r' < /home/judge/log/judge-rotate.conf-CRLF > /home/judge/log/judge-rotate.conf

echo "127.0.0.1    67.cs.nycu" >> /etc/hosts

echo alias curl_http3=\'docker run -it --rm --network host ymuski/curl-http3 curl --http3 -vkL \"$@\"\' >> /etc/bash.bashrc
source /etc/bash.bashrc

docker pull ymuski/curl-http3
# docker run -t --rm --network host badouralix/curl-http3
# docker run -it --rm --network host ymuski/curl-http3 curl --http3 -vkL https://67.cs.nycu:3443
# curl_http3 https://67.cs.nycu:3443

# docker build -f /vagrant/nginx/Dockerfile -t hw4-nginx .
# docker pull bitnami/php-fpm

# docker run -it --rm -d -p 80:80 -p 443:443 \
#   --name hw4-nginx \
#   -v /etc/nginx/conf.d/:/etc/nginx/conf.d \
#   -v /home/judge/www/:/home/judge/www \
#   -v /home/judge/log:/home/judge/log \
#   hw4-nginx
docker-compose -f /vagrant/docker-compose.yaml up -d

# curl -k https://67.cs.nycu
# curl -kL https://67.cs.nycu/info-67.php

# firewall
ufw default deny incoming   # Deny all incoming traffic by default
ufw default allow outgoing  # Allow all outgoing traffic by default

ufw allow from 10.113.67.0/24 to any port 80,443 proto tcp   # Allow HTTP/HTTPS from the subnet

ufw allow proto udp from 10.113.67.0/24 to any port 3443  # Allow HTTP/3 (QUIC) on port 3443

ufw allow ssh               # Allow SSH connections from anywhere

echo "y" | ufw enable                  # Enable the firewall

iptables -I ufw-before-input -p icmp -j DROP # Drop ICMP from other sources
iptables -I ufw-before-input -s 10.113.67.254 -p icmp -j ACCEPT  # Allow ICMP from the gateway


# Fail2ban Filter for Nginx Authentication Failures
cat << EOF | sudo tee /etc/fail2ban/filter.d/nginx-auth.conf
[Definition]
failregex = ^<HOST>.*"(GET|POST).*" (403|401) .*$
ignoreregex = 
EOF

# Fail2ban Jail Configuration for Nginx
cat << EOF | sudo tee /etc/fail2ban/jail.d/nginx-auth.conf
[nginx-auth]
enabled = true
filter = nginx-auth
logpath = /home/judge/log/access.log
maxretry = 3
findtime = 300
bantime = 60
EOF

# Fail2ban Jail Configuration for SSH
cat << EOF | sudo tee /etc/fail2ban/jail.d/sshd.conf
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 60
findtime = 300
EOF

systemctl restart fail2ban

cp /vagrant/iamgoodguy.sh /home/judge/iamgoodguy_CRLF.sh
tr -d '\r' < /home/judge/iamgoodguy_CRLF.sh > /bin/iamgoodguy
chmod 777 /bin/iamgoodguy
