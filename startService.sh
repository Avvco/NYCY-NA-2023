#!/bin/bash

wg-quick up /usr/local/etc/wireguard/wg0.conf

docker-compose -f /vagrant/docker-compose.yaml up -d

systemctl restart fail2ban