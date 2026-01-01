#!/bin/bash
# Akij Infosec Team - Zabbix 7.4 for Raspberry Pi OS 12 (Bookworm)
export DEBIAN_FRONTEND=noninteractive
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
clear
echo -e "${BLUE}################################################################"
echo "#                  AKIJ INFOSEC TEAM                           #"
echo "#          ZABBIX 7.4 (RASPBERRY PI OS 12 SETUP)               #"
echo "################################################################${NC}"
[ "$EUID" -ne 0 ] && echo -e "${RED}Run as root.${NC}" && exit 1
apt-get update -y && apt-get upgrade -y
apt-get install -y wget curl openssl ufw sudo
wget https://repo.zabbix.com/zabbix/7.4/release/raspberrypios/pool/main/z/zabbix-release/zabbix-release_latest_7.4+debian12_all.deb
dpkg -i zabbix-release_latest_7.4+debian12_all.deb
apt-get update -y
apt-get install -y zabbix-server-pgsql zabbix-frontend-php php-pgsql zabbix-apache-conf zabbix-sql-scripts zabbix-agent2
apt-get install -y zabbix-agent2-plugin-mongodb zabbix-agent2-plugin-mssql zabbix-agent2-plugin-postgresql
if ! command -v psql &> /dev/null; then apt-get install -y postgresql; fi
systemctl enable --now postgresql
DB_PASSWORD=$(openssl rand -base64 16 | tr -dc 'a-zA-Z0-9' | head -c 16)
sudo -u postgres psql -c "CREATE USER zabbix WITH PASSWORD '${DB_PASSWORD}';"
sudo -u postgres createdb -O zabbix zabbix
zcat /usr/share/zabbix/sql-scripts/postgresql/server.sql.gz | PGPASSWORD="${DB_PASSWORD}" sudo -u zabbix psql zabbix
sed -i "s/# DBPassword=/DBPassword=${DB_PASSWORD}/" /etc/zabbix/zabbix_server.conf
ufw allow ssh; ufw allow 80/tcp; ufw allow 10050/tcp; ufw allow 10051/tcp; echo "y" | ufw enable
systemctl restart zabbix-server zabbix-agent2 apache2
systemctl enable zabbix-server zabbix-agent2 apache2
IP_ADDR=$(hostname -I | awk '{print $1}')
echo -e "${GREEN}SUCCESS! UI: http://${IP_ADDR}/zabbix | DB Pass: ${DB_PASSWORD}${NC}"
echo "Zabbix Pass: ${DB_PASSWORD}" > /root/zabbix_rpi_creds.txt
