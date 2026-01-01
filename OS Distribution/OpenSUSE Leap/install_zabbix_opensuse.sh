#!/bin/bash
# Akij Infosec Team - Zabbix 7.4 for OpenSUSE Leap 15.6
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
clear
echo -e "${BLUE}################################################################"
echo "#                  AKIJ INFOSEC TEAM                           #"
echo "#          ZABBIX 7.4 (OPENSUSE LEAP 15.6 SETUP)               #"
echo "################################################################${NC}"
[ "$EUID" -ne 0 ] && echo -e "${RED}Run as root.${NC}" && exit 1
zypper --non-interactive update
zypper --non-interactive install wget curl openssl firewalld
rpm -Uvh https://repo.zabbix.com/zabbix/7.4/release/opensuse/15/x86_64/zabbix-release-latest-7.4.sles15.noarch.rpm
zypper --non-interactive refresh
zypper --non-interactive install zabbix-server-pgsql zabbix-web-pgsql zabbix-apache-conf zabbix-sql-scripts zabbix-agent2
zypper --non-interactive install zabbix-agent2-plugin-mongodb zabbix-agent2-plugin-mssql zabbix-agent2-plugin-postgresql
if ! command -v psql &> /dev/null; then zypper --non-interactive install postgresql15-server postgresql15-contrib; systemctl enable --now postgresql; fi
DB_PASSWORD=$(openssl rand -base64 16 | tr -dc 'a-zA-Z0-9' | head -c 16)
sudo -u postgres psql -c "CREATE USER zabbix WITH PASSWORD '${DB_PASSWORD}';"
sudo -u postgres createdb -O zabbix zabbix
zcat /usr/share/zabbix/sql-scripts/postgresql/server.sql.gz | PGPASSWORD="${DB_PASSWORD}" sudo -u zabbix psql zabbix
sed -i "s/# DBPassword=/DBPassword=${DB_PASSWORD}/" /etc/zabbix/zabbix_server.conf
systemctl enable --now firewalld
firewall-cmd --permanent --add-service={http,https} --add-port={10050/tcp,10051/tcp} && firewall-cmd --reload
systemctl restart zabbix-server zabbix-agent2 apache2 php-fpm
systemctl enable zabbix-server zabbix-agent2 apache2 php-fpm
IP_ADDR=$(hostname -I | awk '{print $1}')
echo -e "${GREEN}SUCCESS! UI: http://${IP_ADDR}/zabbix | DB Pass: ${DB_PASSWORD}${NC}"
echo "Zabbix Pass: ${DB_PASSWORD}" > /root/zabbix_opensuse_creds.txt
