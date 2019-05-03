#!/bin/bash

#Yeah, I know this could have been a lot better and used an actual deploy system.
#idc. I want level 7. pls.

DEBIAN_FRONTEND=noninteractive

apt -y update
apt -y upgrade

#Create user and add to sudo

useradd -p $(openssl passwd -1 password) cbagdon
adduser cbagdon sudo

#Copy over dummy netplan YML config and apply the settings

rm -rf /etc/netplan/01-netcfg.yaml
cp assets/netplan_config/01-netcfg.yaml /etc/netplan/

netplan apply

#Install SSH and configure it properly

apt -y install openssh-server

rm -rf /etc/ssh/sshd_config
cp assets/sshd/sshd_config /etc/ssh/
yes "y" | ssh-keygen -q -N "" > /dev/null
mkdir ~/.ssh
cat assets/ssh/id_rsa.pub > ~/.ssh/authorized_keys

service sshd restart

#Install and configure Fail2Ban
apt -y install fail2ban

rm -rf /etc/fail2ban/jail.local
cp assets/fail2ban/jail.local /etc/fail2ban/

cp assets/fail2ban/nginx-dos.conf /etc/fail2ban/filter.d
cp assets/fail2ban/portscan.conf /etc/fail2ban/filter.d

service fail2ban restart

#Copy and set up cron scripts for updating packages and detecting crontab changes

apt -y install mailutils

cp -r assets/scripts /home/cbagdon
{ crontab -l -u cbagdon; echo '0 4 * * SUN /home/cbagdon/scripts/update_script.sh'; } | crontab -u cbagdon -
{ crontab -l -u cbagdon; echo '@reboot /home/christian/scripts/update_script.sh'; } | crontab -u cbagdon -

{ crontab -l -u cbagdon; echo '0 0 * * * SUN /home/cbagdon/scripts/check_cron.sh'; } | crontab -u cbagdon -

#Set up nginx and copy website files over
apt -y install nginx

rm -rf /var/www/html/index.nginx-debian.html
cp assets/nginx/index.nginx-debian.html /var/www/html/

#Set up SSL
yes "y" | openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/nginx-selfsigned.key -out /etc/ssl/certs/nginx-selfsigned.crt \
	-subj "/C=US/ST=California/L=Fremont/O=42 Silicon Valley/OU=Student/CN=localhost"
yes "y" | openssl dhparam -dsaparam -out /etc/nginx/dhparam.pem 4096
cp assets/ssl/self-signed.conf /etc/nginx/snippets/
cp assets/ssl/ssl-params.conf /etc/nginx/snippets/

rm -rf /etc/nginx/sites-available/default
cp assets/ssl/default /etc/nginx/sites-available/

#Set up Firewall; Default DROP connections
ufw enable
ufw default deny incoming
ufw default allow outgoing
ufw allow 5647
ufw allow 443
ufw allow 80
ufw allow 'Nginx Full'
ufw reload

#Reboot Nginx server, hopefully we have a live website
systemctl restart nginx
