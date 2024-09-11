
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
   ```

2. **Make the Script Executable**

   Before running the script, make sure it’s executable:

   ```bash
   chmod +x netbox-install.sh
   ```

3. **Run the Script**

   Execute the script to begin the installation:

   ```bash
   sudo ./netbox-install.sh
   ```

   The script will prompt you to choose which version of NetBox you want to install. If no version is chosen, the latest version will be installed by default.

4. **Check Output and Configuration**

   After the script completes, a file named `netbox_credentials.txt` will be generated in `/opt/netbox/` with important configuration details such as:

   - PostgreSQL username and password
   - NetBox secret key
   - Admin username and password
   - Installed NetBox version

   Example:

   ```
   NetBox PostgreSQL Database:
   ---------------------------
   Username: netbox
   Password: random-password
   Database: netbox

   NetBox Configuration Secret Key:
   --------------------------------
   random-secret-key

   NetBox Admin Credentials:
   ---------------------------
   Username: admin
   Password: admin

   NetBox Version Installed: vX.Y.Z

   Generated on: YYYY-MM-DD
   ```

   The script ensures that this file has restricted access (`chmod 600`) to prevent unauthorized access.

## Configuration Details

### ALLOWED_HOSTS

The script automatically populates the `ALLOWED_HOSTS` setting in the `configuration.py` file based on:

- The system’s IP address.
- The system's hostname.
- A forward DNS lookup of the IP address.
- A reverse DNS (PTR) lookup of the IP address.

This ensures that NetBox is accessible via the correct hostnames and IP addresses.

### Admin Credentials

The script will automatically create a superuser for NetBox with the following credentials:

- **Username**: `admin`
- **Password**: `admin`

You can change the password after logging in by using the Django admin interface or through the command line.

## Requirements

This script will automatically install the following packages:

- PostgreSQL
- Redis
- Python 3 and required development libraries
- Gunicorn
- Nginx
- Git
- DNS utilities (for hostname and DNS detection)

## Troubleshooting

If you encounter any issues during installation:

- **PostgreSQL issues**: Ensure PostgreSQL is running and accessible.
- **Redis issues**: Ensure the Redis service is active.
- **Gunicorn/Nginx issues**: If the web interface does not work, check the systemd status for `netbox` and `netbox-rq` services using:

  ```bash
  sudo systemctl status netbox
  sudo systemctl status netbox-rq
  ```

  Also, check Nginx logs for any configuration errors.

## License

This project is licensed under the MIT License. See the `LICENSE` file for more details.

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## Credits

- [NetBox](https://github.com/netbox-community/netbox) community for the source code.
