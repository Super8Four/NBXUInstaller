# NetBox Installation Script

This script automates the installation of [NetBox](https://github.com/netbox-community/netbox) on an Ubuntu server. It performs all necessary tasks, including:

- Installing dependencies like PostgreSQL, Redis, and required Python libraries.
- Setting up PostgreSQL with a randomly generated password for the NetBox database.
- Cloning the desired NetBox version from GitHub.
- Creating a superuser with a default username of `admin` and password of `admin`.
- Automatically detecting the server's IP address, hostname, and DNS records to configure the `ALLOWED_HOSTS` in the NetBox configuration.
- Setting up Gunicorn and Nginx for NetBox's web interface.
- Ensuring proper housekeeping and cron jobs are in place.

## Prerequisites

Ensure your server is running an updated version of Ubuntu. This script has been tested with fully updated Ubuntu systems.

## Features

- **Dynamic Version Selection**: The script fetches the available versions of NetBox from GitHub and allows you to choose which version to install.
- **Randomly Generated Database Password**: A secure 12-character password (comprising upper case, lower case, numbers, and symbols) is generated for the PostgreSQL `netbox` user.
- **Automatic Host Detection**: The script automatically detects the system's IP address, hostname, and performs DNS lookups. These values are then used to populate the `ALLOWED_HOSTS` configuration in NetBox.
- **Superuser Creation**: A default admin account is created with the username `admin` and password `admin`.

## How to Use

1. **Clone the Repository**

   Download or clone this repository to your server:

   ```bash
   git clone https://github.com/your-repo/netbox-install-script.git
   cd netbox-install-script
