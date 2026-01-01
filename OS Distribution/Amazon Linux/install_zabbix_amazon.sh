#!/bin/bash
# Akij Infosec Team - Zabbix 7.4 for Amazon Linux 2023
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
clear
echo -e "${BLUE}################################################################"
echo "#                  AKIJ INFOSEC TEAM                           #"
echo "#          ZABBIX 7.4 (AMAZON LINUX 2023 SETUP)                #"
echo "################################################################${NC}"
[ "$EUID" -ne 0 ] && echo -e "${RED}Run as root.${NC}" && exit 1
dnf update -y
dnf install -y wget curl openssl
rpm -Uvh https://repo.zabbix.com/zabbix/7.4/release/amazonlinux/2023/x86_64/zabbix-release-latest-7.4.el9.noarch.rpm
dnf clean all
dnf install -y zabbix-server-pgsql zabbix-web-pgsql zabbix-apache-conf zabbix-sql-scripts zabbix-selinux-policy zabbix-agent2
dnf install -y zabbix-agent2-plugin-mongodb zabbix-agent2-plugin-mssql zabbix-agent2-plugin-postgresql
if ! command -v psql &> /dev/null; then dnf install -y postgresql15-server; postgresql-setup --initdb; systemctl enable --now postgresql; fi
DB_PASSWORD=$(openssl rand -base64 16 | tr -dc 'a-zA-Z0-9' | head -c 16)
sudo -u postgres psql -c "CREATE USER zabbix WITH PASSWORD '${DB_PASSWORD}';"
sudo -u postgres createdb -O zabbix zabbix
zcat /usr/share/zabbix/sql-scripts/postgresql/server.sql.gz | PGPASSWORD="${DB_PASSWORD}" sudo -u zabbix psql zabbix
sed -i "s/# DBPassword=/DBPassword=${DB_PASSWORD}/" /etc/zabbix/zabbix_server.conf
# Note: Amazon Linux 2023 doesn't use firewalld by default, usually managed via Security Groups
systemctl restart zabbix-server zabbix-agent2 httpd php-fpm
systemctl enable zabbix-server zabbix-agent2 httpd php-fpm
IP_ADDR=$(hostname -I | awk '{print $1}')
echo -e "${GREEN}SUCCESS! UI: http://${IP_ADDR}/zabbix | DB Pass: ${DB_PASSWORD}${NC}"
echo "Zabbix Pass: ${DB_PASSWORD}" > /root/zabbix_amazon_creds.txt
