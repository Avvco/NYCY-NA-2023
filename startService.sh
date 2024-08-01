#!/bin/bash

wg-quick up /usr/local/etc/wireguard/wg0.conf

# docker-compose -f /vagrant/docker-compose.yaml up -d

# systemctl restart sshd
# systemctl restart rsyslog

# systemctl restart fail2ban