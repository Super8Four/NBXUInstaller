#!/bin/bash

# Variables
NETBOX_DB_USER="netbox"
NETBOX_DIR="/opt/netbox"
ALLOWED_HOSTS="['*']"  # Modify with your specific hostnames/IPs if needed
PASSWORD_FILE="/opt/netbox/netbox_credentials.txt"

# Function to list available NetBox versions from GitHub
list_versions() {
  echo "Fetching available NetBox versions..."
  available_versions=$(curl -s https://api.github.com/repos/netbox-community/netbox/tags | grep 'name' | cut -d '"' -f 4)
  echo "Available versions of NetBox:"
  echo "$available_versions"
}

# Function to prompt user for version input
prompt_for_version() {
  echo "Enter the version of NetBox you want to install (or press Enter to install the latest stable version):"
  read -r NETBOX_VERSION
  if [ -z "$NETBOX_VERSION" ]; then
    NETBOX_VERSION=$(echo "$available_versions" | head -n 1)  # Default to the latest version
  fi
  echo "Installing NetBox version: $NETBOX_VERSION"
}

# Check available versions
list_versions
prompt_for_version

# Generate a 12-character password with upper, lower, number, and symbol
NETBOX_DB_PASSWORD=$(openssl rand -base64 12 | tr -dc 'A-Za-z0-9@#%&*=' | head -c 12)

# Update system
sudo apt update
sudo apt -y upgrade

# Install required packages
sudo apt install -y postgresql redis-server python3 python3-pip python3-venv python3-dev \
  build-essential libxml2-dev libxslt1-dev libffi-dev libpq-dev libssl-dev zlib1g-dev git nginx

# Setup PostgreSQL database
sudo -u postgres psql << EOF
CREATE DATABASE netbox;
CREATE USER $NETBOX_DB_USER WITH PASSWORD '$NETBOX_DB_PASSWORD';
ALTER DATABASE netbox OWNER TO $NETBOX_DB_USER;
\connect netbox;
GRANT CREATE ON SCHEMA public TO $NETBOX_DB_USER;
\q
EOF

# Check PostgreSQL version
psql -V

# Check Redis server
redis-server -v

# Clone the specified NetBox version from GitHub
sudo mkdir -p $NETBOX_DIR
cd $NETBOX_DIR
sudo git clone -b "$NETBOX_VERSION" --depth 1 https://github.com/netbox-community/netbox.git .

# Create system user
sudo adduser --system --group netbox
sudo chown --recursive netbox /opt/netbox/netbox/media/
sudo chown --recursive netbox /opt/netbox/netbox/reports/
sudo chown --recursive netbox /opt/netbox/netbox/scripts/

# Create virtual environment
sudo python3 -m venv /opt/netbox/venv
source /opt/netbox/venv/bin/activate

# Install Python packages
pip install -r /opt/netbox/requirements.txt

# Configuration setup
cd /opt/netbox/netbox/netbox/
sudo cp configuration_example.py configuration.py

# Modify configuration.py
sudo sed -i "s/ALLOWED_HOSTS = \[\]/ALLOWED_HOSTS = $ALLOWED_HOSTS/" configuration.py
sudo sed -i "s/'USER': 'netbox',/'USER': '$NETBOX_DB_USER',/" configuration.py
sudo sed -i "s/'PASSWORD': ''/'PASSWORD': '$NETBOX_DB_PASSWORD'/" configuration.py

# Generate secret key
SECRET_KEY=$(python3 ../generate_secret_key.py)
sudo sed -i "s/SECRET_KEY = ''/SECRET_KEY = '$SECRET_KEY'/" configuration.py

# Install Redis and database configuration in configuration.py
sudo sed -i "/^REDIS = {/ a\ 'tasks': {'HOST': 'localhost', 'PORT': 6379, 'DATABASE': 0, 'SSL': False}, 'caching': {'HOST': 'localhost', 'PORT': 6379, 'DATABASE': 1, 'SSL': False}" configuration.py

# Run the upgrade script to finalize installation
sudo /opt/netbox/upgrade.sh

# Create NetBox superuser with username 'admin' and password 'admin'
source /opt/netbox/venv/bin/activate
cd /opt/netbox/netbox
python3 manage.py shell <<EOF
from django.contrib.auth.models import User
if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser('admin', 'admin@example.com', 'admin')
EOF

# Gunicorn and systemd setup
sudo cp /opt/netbox/contrib/gunicorn.py /opt/netbox/gunicorn.py
sudo cp /opt/netbox/contrib/*.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now netbox netbox-rq

# Nginx setup
sudo cp /opt/netbox/contrib/nginx.conf /etc/nginx/sites-available/netbox
sudo ln -s /etc/nginx/sites-available/netbox /etc/nginx/sites-enabled/netbox
sudo rm /etc/nginx/sites-enabled/default
sudo systemctl restart nginx

# Start housekeeping
sudo ln -s /opt/netbox/contrib/netbox-housekeeping.sh /etc/cron.daily/netbox-housekeeping

# Output credentials to a text file in /opt/netbox folder
sudo bash -c "cat > $PASSWORD_FILE << EOL
NetBox PostgreSQL Database:
---------------------------
Username: $NETBOX_DB_USER
Password: $NETBOX_DB_PASSWORD
Database: netbox

NetBox Configuration Secret Key:
--------------------------------
$SECRET_KEY

NetBox Admin Credentials:
---------------------------
Username: admin
Password: admin

NetBox Version Installed: $NETBOX_VERSION

Generated on: $(date)
EOL"

# Ensure the credentials file has restricted access
sudo chmod 600 $PASSWORD_FILE

# Output confirmation
echo "NetBox Database and Admin credentials saved to $PASSWORD_FILE"
