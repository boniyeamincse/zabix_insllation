# 🚀 Zabbix Automation Suite for the Community

[![Zabbix Version](https://img.shields.io/badge/Zabbix-7.4-blue)](https://www.zabbix.com/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Community Supported](https://img.shields.io/badge/Community-Supported-orange)](#contributing)

Welcome to the **Zabbix Multi-OS Installation Suite**! This project aims to provide the community with fully automated, production-ready Bash scripts for deploying Zabbix 7.4 monitoring infrastructure on a wide variety of Linux distributions.

Initially developed for the **Akij Infosec Team**, this project is now public to help system administrators and security engineers worldwide set up monitoring in minutes.

---

## 🌟 What Makes This Suite Special?

- **Zero-Touch Deployment**: From system updates to database importing, everything is automated.
- **Security-Hardenend**: 
  - Generates complex random passwords for databases.
  - Automatically configures OS firewalls (UFW or Firewalld).
  - Handles SELinux configurations (for RHEL/CentOS/Rocky).
- **Branded & Professional**: Branded output with clear post-installation instructions and credential summaries.
- **Wide OS Coverage**: Supports 11+ distributions from Ubuntu to Amazon Linux and SUSE.

---

## 📂 Project Overview

| Category | Supported Distributions |
| :--- | :--- |
| **Ubuntu/Debian** | Ubuntu 24.04, Debian 12, Raspberry Pi OS 12 |
| **RHEL-Based** | Rocky Linux 9, CentOS Stream 9, Alma Linux 9, Oracle Linux 9, RHEL 9 |
| **SUSE-Based** | OpenSUSE Leap 15.6, SLES 15 |
| **Cloud** | Amazon Linux 2023 |

---

## 🛠️ Usage Instructions

Deployment is as simple as running two commands. Choose the script for your OS and run:

```bash
# Example for Ubuntu 24.04
chmod +x "OS Distribution/Ubuntu/install_zabbix.sh"
sudo "./OS Distribution/Ubuntu/install_zabbix.sh"
```

### Script Locations:
- `OS Distribution/` contains the Server, Frontend, and Agent 2 installation scripts.
- `agent/` (Work in Progress) will contain specialized agent installers for various legacy and niche hardware.

---

## 🤝 Contributing (Help the Community!)

This is a community-driven project. We welcome contributions for:
- [ ] Support for older OS versions (CentOS 7, Ubuntu 20.04, etc.)
- [ ] Integration for other databases (MySQL/MariaDB)
- [ ] Dockerized versions of these installation scripts
- [ ] Bug fixes and performance improvements

**To contribute:**
1. Fork the repository.
2. Create your feature branch (`git checkout -b feature/AmazingFeature`).
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`).
4. Push to the branch (`git push origin feature/AmazingFeature`).
5. Open a Pull Request.

---

## 🛡️ Security Disclaimer
These scripts generate credentials locally. Always ensure you are running these in a secure environment. Credentials are saved to the `/root/` directory by default for reference; make sure to manage these files according to your organization's security policy.

---
**Maintained by the Community & Akij Infosec Team**
