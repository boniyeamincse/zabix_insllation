#!/bin/bash
# Akij Infosec Team - Zabbix 7.4 for Alma Linux 9
export DEBIAN_FRONTEND=noninteractive
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
clear
echo -e "${BLUE}################################################################"
echo "#                  AKIJ INFOSEC TEAM                           #"
echo "#             ZABBIX 7.4 (ALMA LINUX 9 SETUP)                  #"
echo "################################################################${NC}"
[ "$EUID" -ne 0 ] && echo -e "${RED}Run as root.${NC}" && exit 1
echo -e "${BLUE}[0/8] Updating System...${NC}"; dnf update -y
dnf install -y wget curl openssl firewalld
[ -f /etc/yum.repos.d/epel.repo ] && sed -i '/\[epel\]/a excludepkgs=zabbix*' /etc/yum.repos.d/epel.repo
echo -e "${BLUE}[2/8] Repository...${NC}"
rpm -Uvh https://repo.zabbix.com/zabbix/7.4/release/alma/9/noarch/zabbix-release-latest-7.4.el9.noarch.rpm
dnf clean all
echo -e "${BLUE}[3/8] Packages...${NC}"
dnf install -y zabbix-server-pgsql zabbix-web-pgsql zabbix-apache-conf zabbix-sql-scripts zabbix-selinux-policy zabbix-agent2
dnf install -y zabbix-agent2-plugin-mongodb zabbix-agent2-plugin-mssql zabbix-agent2-plugin-postgresql
echo -e "${BLUE}[5/8] DB Setup...${NC}"
if ! command -v psql &> /dev/null; then dnf install -y postgresql-server postgresql-contrib; postgresql-setup --initdb; fi
systemctl enable --now postgresql
DB_PASSWORD=$(openssl rand -base64 16 | tr -dc 'a-zA-Z0-9' | head -c 16)
sudo -u postgres psql -c "CREATE USER zabbix WITH PASSWORD '${DB_PASSWORD}';"
sudo -u postgres createdb -O zabbix zabbix
zcat /usr/share/zabbix/sql-scripts/postgresql/server.sql.gz | PGPASSWORD="${DB_PASSWORD}" sudo -u zabbix psql zabbix
sed -i "s/# DBPassword=/DBPassword=${DB_PASSWORD}/" /etc/zabbix/zabbix_server.conf
echo -e "${BLUE}[7/8] Firewall...${NC}"
systemctl enable --now firewalld
firewall-cmd --permanent --add-service={http,https} --add-port={10050/tcp,10051/tcp} && firewall-cmd --reload
systemctl restart zabbix-server zabbix-agent2 httpd php-fpm
systemctl enable zabbix-server zabbix-agent2 httpd php-fpm
IP_ADDR=$(hostname -I | awk '{print $1}')
echo -e "${GREEN}SUCCESS! UI: http://${IP_ADDR}/zabbix | DB Pass: ${DB_PASSWORD}${NC}"
echo "Zabbix Pass: ${DB_PASSWORD}" > /root/zabbix_alma_creds.txt
