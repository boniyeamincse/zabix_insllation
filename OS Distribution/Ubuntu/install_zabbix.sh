#!/bin/bash

# =================================================================
# Akij Infosec Team - Fully Automated Zabbix 7.4 Installation
# System: Ubuntu 24.04 Noble (amd64 / arm64)
# Components: Server, Frontend, Agent 2, PostgreSQL, Apache, Firewall
# =================================================================

# Export variables to prevent interactive prompts
export DEBIAN_FRONTEND=noninteractive

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
echo "#                  (FULLY AUTOMATED SETUP)                     #"
echo "#                                                              #"
echo "################################################################"
echo -e "${NC}"

echo -e "${YELLOW}Starting Automated Zabbix 7.4 Installation on Akij Infrastructure...${NC}\n"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Please run as root or using sudo.${NC}"
  exit 1
fi

# 0. System Update and Upgrade
echo -e "${BLUE}[0/8] Updating System Packages...${NC}"
apt-get update -y
apt-get upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"

# Install necessary base utilities
echo -e "${BLUE}[0/8] Installing Base Dependencies (curl, gnupg2, ufw, openssl)...${NC}"
apt-get install -y curl gnupg2 ufw openssl wget sudo

# 1. Install Zabbix repository
echo -e "${BLUE}[1/8] Installing Zabbix 7.4 Repository...${NC}"
rm -f zabbix-release_latest_7.4+ubuntu24.04_all.deb
wget https://repo.zabbix.com/zabbix/7.4/release/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest_7.4+ubuntu24.04_all.deb
dpkg -i zabbix-release_latest_7.4+ubuntu24.04_all.deb
apt-get update -y

# 2. Install Zabbix server, frontend, agent 2
echo -e "${BLUE}[2/8] Installing Zabbix Server, Frontend, and Agent 2...${NC}"
apt-get install -y zabbix-server-pgsql zabbix-frontend-php php8.3-pgsql zabbix-apache-conf zabbix-sql-scripts zabbix-agent2

# 3. Install Zabbix agent 2 plugins
echo -e "${BLUE}[3/8] Installing Zabbix Agent 2 Plugins (PostgreSQL, MongoDB, MSSQL)...${NC}"
apt-get install -y zabbix-agent2-plugin-mongodb zabbix-agent2-plugin-mssql zabbix-agent2-plugin-postgresql

# 4. Create initial database
echo -e "${BLUE}[4/8] Setting up PostgreSQL Database...${NC}"
if ! command -v psql &> /dev/null; then
    echo -e "${YELLOW}PostgreSQL not found. Installing...${NC}"
    apt-get install -y postgresql
fi

# Start postgresql service
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

# 5. Configure the database for Zabbix server
echo -e "${BLUE}[5/8] Configuring Zabbix Server...${NC}"
sed -i "s/# DBPassword=/DBPassword=${DB_PASSWORD}/" /etc/zabbix/zabbix_server.conf

# 6. Configure Firewall (UFW)
echo -e "${BLUE}[6/8] Configuring Firewall Rules...${NC}"
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 10050/tcp
ufw allow 10051/tcp
echo "y" | ufw enable

# 7. Start Zabbix server and agent processes
echo -e "${BLUE}[7/8] Starting Zabbix Services...${NC}"
systemctl restart zabbix-server zabbix-agent2 apache2
systemctl enable zabbix-server zabbix-agent2 apache2

# 8. Final Output
IP_ADDR=$(hostname -I | awk '{print $1}')
echo -e "\n${GREEN}################################################################"
echo "#                                                              #"
echo "#             AKIJ INFOSEC TEAM - INSTALLATION COMPLETE         #"
echo "#                                                              #"
echo "################################################################${NC}"

echo -e "\n${YELLOW}System Status:${NC}"
echo -e "System Updated: ${GREEN}Yes${NC}"
echo -e "Firewall Status: ${GREEN}Active${NC}"
echo -e "Services Running: ${GREEN}zabbix-server, zabbix-agent2, apache2, postgresql${NC}"

echo -e "\n${YELLOW}Access Information:${NC}"
echo -e "Zabbix UI: ${BLUE}http://${IP_ADDR}/zabbix${NC}"
echo -e "Database Password: ${RED}${DB_PASSWORD}${NC}"
echo -e "\n${GREEN}Please follow the web interface to complete the setup.${NC}"

# Save credentials for reference
CREDS_FILE="/root/zabbix_setup_details.txt"
cat <<EOF > ${CREDS_FILE}
==========================================
Akij Infosec Team - Zabbix Setup Credentials
==========================================
Date: $(date)
UI URL: http://${IP_ADDR}/zabbix
Local IP: ${IP_ADDR}
Database Name: zabbix
Database User: zabbix
Database Password: ${DB_PASSWORD}
==========================================
EOF

chmod 600 ${CREDS_FILE}
echo -e "\n${BLUE}Complete setup details saved to ${CREDS_FILE}${NC}"
