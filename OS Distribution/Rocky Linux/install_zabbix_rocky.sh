#!/bin/bash

# =================================================================
# Akij Infosec Team - Fully Automated Zabbix 7.4 Installation
# System: Rocky Linux 9 (EL9 / amd64 / arm64)
# Components: Server, Frontend, Agent 2, PostgreSQL, Apache, Firewall
# =================================================================

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Banner
clear
echo -e "${BLUE}"
echo "################################################################"
echo "#                                                              #"
echo "#                  AKIJ INFOSEC TEAM                           #"
echo "#             ZABBIX 7.4 ENTERPRISE MONITORING                 #"
echo "#                  (ROCKY LINUX 9 SETUP)                       #"
echo "#                                                              #"
echo "################################################################"
echo -e "${NC}"

echo -e "${YELLOW}Starting Automated Zabbix 7.4 Installation on Rocky Linux...${NC}\n"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Please run as root or using sudo.${NC}"
  exit 1
fi

# 0. System Update
echo -e "${BLUE}[0/8] Updating System Packages...${NC}"
dnf update -y

# Install base utilities
dnf install -y wget curl openssl firewalld

# 1. Handle EPEL Repository
if [ -f /etc/yum.repos.d/epel.repo ]; then
    echo -e "${YELLOW}EPEL found. Excluding Zabbix packages to prevent conflicts...${NC}"
    if ! grep -q "excludepkgs=zabbix\*" /etc/yum.repos.d/epel.repo; then
        sed -i '/\[epel\]/a excludepkgs=zabbix*' /etc/yum.repos.d/epel.repo
    fi
fi

# 2. Install Zabbix repository
echo -e "${BLUE}[2/8] Installing Zabbix 7.4 Repository...${NC}"
rpm -Uvh https://repo.zabbix.com/zabbix/7.4/release/rocky/9/noarch/zabbix-release-latest-7.4.el9.noarch.rpm
dnf clean all

# 3. Install Zabbix server, frontend, agent 2
echo -e "${BLUE}[3/8] Installing Zabbix Server, Frontend, and Agent 2...${NC}"
dnf install -y zabbix-server-pgsql zabbix-web-pgsql zabbix-apache-conf zabbix-sql-scripts zabbix-selinux-policy zabbix-agent2

# 4. Install Zabbix agent 2 plugins
echo -e "${BLUE}[4/8] Installing Zabbix Agent 2 Plugins (PostgreSQL, MongoDB, MSSQL)...${NC}"
dnf install -y zabbix-agent2-plugin-mongodb zabbix-agent2-plugin-mssql zabbix-agent2-plugin-postgresql

# 5. Setup PostgreSQL
echo -e "${BLUE}[5/8] Setting up PostgreSQL...${NC}"
if ! command -v psql &> /dev/null; then
    echo -e "${YELLOW}PostgreSQL not found. Installing...${NC}"
    dnf install -y postgresql-server postgresql-contrib
    postgresql-setup --initdb
fi

systemctl start postgresql
systemctl enable postgresql

# Generate a secure random password for zabbix user
DB_PASSWORD=$(openssl rand -base64 16 | tr -dc 'a-zA-Z0-9' | head -c 16)

echo -e "${GREEN}Creating Zabbix database and user...${NC}"
sudo -u postgres psql -c "DROP USER IF EXISTS zabbix;"
sudo -u postgres psql -c "CREATE USER zabbix WITH PASSWORD '${DB_PASSWORD}';"
sudo -u postgres psql -c "DROP DATABASE IF EXISTS zabbix;"
sudo -u postgres psql -c "CREATE DATABASE zabbix OWNER zabbix;"

# Import initial schema and data
echo -e "${BLUE}Importing Zabbix Schema (this may take a minute)...${NC}"
zcat /usr/share/zabbix/sql-scripts/postgresql/server.sql.gz | PGPASSWORD="${DB_PASSWORD}" sudo -u zabbix psql zabbix

# 6. Configure Zabbix Server
echo -e "${BLUE}[6/8] Configuring Zabbix Server...${NC}"
sed -i "s/# DBPassword=/DBPassword=${DB_PASSWORD}/" /etc/zabbix/zabbix_server.conf

# 7. Configure Firewall (Firewalld)
echo -e "${BLUE}[7/8] Configuring Firewall (Firewalld)...${NC}"
systemctl start firewalld
systemctl enable firewalld
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --permanent --add-port=10050/tcp
firewall-cmd --permanent --add-port=10051/tcp
firewall-cmd --reload

# 8. Start Zabbix Services
echo -e "${BLUE}[8/8] Starting Zabbix Services...${NC}"
systemctl restart zabbix-server zabbix-agent2 httpd php-fpm
systemctl enable zabbix-server zabbix-agent2 httpd php-fpm

# Final Output
IP_ADDR=$(hostname -I | awk '{print $1}')
echo -e "\n${GREEN}################################################################"
echo "#                                                              #"
echo "#             AKIJ INFOSEC TEAM - INSTALLATION COMPLETE         #"
echo "#                                                              #"
echo "################################################################${NC}"

echo -e "\n${YELLOW}System Status:${NC}"
echo -e "Platform: ${GREEN}Rocky Linux 9${NC}"
echo -e "Firewall: ${GREEN}Active (Firewalld)${NC}"
echo -e "Services: ${GREEN}zabbix-server, zabbix-agent2, httpd, php-fpm, postgresql${NC}"

echo -e "\n${YELLOW}Access Information:${NC}"
echo -e "Zabbix UI: ${BLUE}http://${IP_ADDR}/zabbix${NC}"
echo -e "Database Password: ${RED}${DB_PASSWORD}${NC}"
echo -e "\n${GREEN}Complete the setup via the web interface.${NC}"

# Save credentials
CREDS_FILE="/root/zabbix_rocky_creds.txt"
cat <<EOF > ${CREDS_FILE}
==========================================
Akij Infosec Team - Zabbix Rocky Linux Setup
==========================================
Date: $(date)
UI URL: http://${IP_ADDR}/zabbix
Database User: zabbix
Database Password: ${DB_PASSWORD}
==========================================
EOF

chmod 600 ${CREDS_FILE}
echo -e "\n${BLUE}Credentials saved to ${CREDS_FILE}${NC}"
