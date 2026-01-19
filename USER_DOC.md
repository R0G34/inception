# User Documentation - 42 Inception Project

## Overview

The 42 Inception project is a system administration exercise that sets up a complete web infrastructure using Docker containers. This documentation will guide you through using and maintaining the deployed services.

## Services Overview

This project consists of three interconnected services running in isolated Docker containers:

### 1. MariaDB
- **Purpose**: Database server for storing WordPress data
- **Technology**: MariaDB 10.x on Debian Linux 13.3
- **Function**: Stores all WordPress content including posts, pages, users, settings, and plugins data
- **Internal Port**: 3306 (not exposed to host)
- **Access**: Only accessible by the WordPress container via Docker network

### 2. WordPress
- **Purpose**: Content Management System (CMS) for website management
- **Technology**: WordPress with PHP 8.2-FPM on Debian Linux 13.3
- **Function**: Provides the web application logic and serves dynamic content
- **Internal Port**: 9000 (PHP-FPM)
- **Access**: Communicates with MariaDB for data and with Nginx for serving requests

### 3. Nginx
- **Purpose**: Web server and reverse proxy
- **Technology**: Nginx on Debian Linux 13.3 with SSL/TLS encryption
- **Function**: Entry point for all web traffic, handles HTTPS connections, and proxies requests to WordPress
- **Exposed Port**: 443 (HTTPS)
- **Security**: Enforces TLSv1.2 and TLSv1.3 protocols for secure connections

## Starting the Project

### Quick Start
To start all services, simply run:

```bash
make
```

Or explicitly:

```bash
make all
```

This command will:
1. Create necessary data directories (`/home/abausa-v/data/mariadb` and `/home/abausa-v/data/wordpress`)
2. Build Docker images for all three services
3. Start all containers in detached mode

### First-Time Setup
When you run the project for the first time:
- MariaDB will initialize the database with the credentials from `.env`
- WordPress will be automatically installed and configured
- SSL certificates will be generated for HTTPS connections

The initialization process may take 1-2 minutes. Please wait for all containers to be healthy before accessing the website.

## Stopping the Project

### Stop Services (Preserve Data)
To stop all running containers while keeping your data:

```bash
make down
```

This stops the containers but preserves all data in the volumes. You can restart with `make run` later.

### Stop and Remove Volumes
To stop containers and remove all Docker volumes:

```bash
make clean
```

⚠️ **Warning**: This will stop containers and remove volumes, but data in `/home/abausa-v/data/` will remain.

### Complete Cleanup
For a complete cleanup including all Docker resources and data:

```bash
make fclean
```

⚠️ **Critical Warning**: This command will:
- Stop all containers
- Remove all Docker volumes
- Delete all Docker images, containers, and build cache
- **Permanently delete** all data from `/home/abausa-v/data/mariadb` and `/home/abausa-v/data/wordpress`

**Your database and website files will be permanently lost. Use with caution!**

## Accessing Services

### Access the WordPress Website

Open your web browser and navigate to:

```
https://abausa-v.42.fr
```

**Note**: Since this uses a self-signed SSL certificate, your browser will display a security warning. This is expected behavior. Click "Advanced" and proceed to the site.

**Host File Configuration**: Ensure your `/etc/hosts` file contains the following entry:

```
YOUR IP    abausa-v.42.fr
```

### Access the WordPress Admin Panel

To manage your WordPress site (create posts, install plugins, etc.):

```
https://abausa-v.42.fr/wp-admin
```

Log in using the administrator credentials (see Credentials Management section below).

## Credentials Management

All sensitive credentials are stored in the `srcs/.env` file. **Never commit this file to version control.**

### Location
```
srcs/.env
```

### Administrator Credentials
Use these credentials to log into the WordPress admin panel (`/wp-admin`):

- **Username**: Value of `ADMIN_USER` in `.env`
- **Password**: Value of `ADMIN_PASSWORD` in `.env`
- **Email**: Value of `ADMIN_EMAIL` in `.env`

### Database Credentials
These are used internally by WordPress to connect to MariaDB:

- **Database Name**: `SQL_DATABASE` 
- **Database User**: `SQL_USER`
- **Database Password**: `SQL_PASSWORD`
- **Database Root Password**: `SQL_ROOT_PASSWORD`
- **Database Host**: `SQL_HOST`

### Additional User Credentials
A secondary WordPress user is also created:

- **Username**: Value of `USER1_LOGIN` in `.env`
- **Password**: Value of `USER1_PASSWORD` in `.env`
- **Email**: Value of `USER1_EMAIL` in `.env`

**Security Recommendation**: Change all default passwords in the `.env` file before deploying to production.

## Service Health Checks

### Check Container Status

To verify all containers are running:

```bash
docker ps
```

**Expected Output**: You should see three containers running:
- `nginx` (status: Up)
- `wordpress` (status: Up)
- `mariadb` (status: Up)

If any container shows "Restarting" or is not listed, there may be a configuration issue.

### View Container Logs

To troubleshoot issues, check the logs of individual containers:

**Nginx logs:**
```bash
docker logs nginx
```

**WordPress logs:**
```bash
docker logs wordpress
```

**MariaDB logs:**
```bash
docker logs mariadb
```

For continuous log streaming (follow mode):
```bash
docker logs -f <container-name>
```

Press `Ctrl+C` to stop following logs.

### Test Website Accessibility

**Command-line test:**
```bash
curl -k https://abausa-v.42.fr
```

The `-k` flag allows insecure connections (self-signed certificate). You should receive HTML output from WordPress.

**Browser test:**
Simply navigate to `https://abausa-v.42.fr` in your web browser.

### Verify Database Connection

To verify WordPress can connect to MariaDB:

1. Check WordPress logs: `docker logs wordpress`
2. Look for successful database connection messages
3. Ensure no "Error establishing database connection" messages appear

### Check Docker Network

To verify the Docker network is properly configured:

```bash
docker network inspect inception
```

You should see all three containers listed in the "Containers" section.

### Check Volumes and Data Persistence

To verify data volumes are mounted correctly:

```bash
docker volume ls
```

You should see:
- `mariadb-vol`
- `wordpress-vol`

To check the actual data on the host:

```bash
ls -la /home/abausa-v/data/mariadb
ls -la /home/abausa-v/data/wordpress
```

These directories should contain database files and WordPress files respectively.

## Maintenance

### Restarting Services
If you need to restart a specific service:

```bash
docker compose -f srcs/docker-compose.yml restart <service-name>
```

Example:
```bash
docker compose -f srcs/docker-compose.yml restart wordpress
```

### Rebuilding After Changes
If you modify Dockerfiles or configurations:

```bash
make re
```

This will stop everything, clean up, rebuild, and restart all services.

### Backing Up Data
To backup your WordPress site and database:

```bash
# Create backup directory
mkdir -p ~/inception-backup

# Copy data
sudo cp -r /home/abausa-v/data/mariadb ~/inception-backup/
sudo cp -r /home/abausa-v/data/wordpress ~/inception-backup/
sudo cp srcs/.env ~/inception-backup/
```

### Restoring Data
To restore from a backup:

```bash
# Stop services
make down

# Restore data
sudo rm -rf /home/abausa-v/data/mariadb/*
sudo rm -rf /home/abausa-v/data/wordpress/*
sudo cp -r ~/inception-backup/mariadb/* /home/abausa-v/data/mariadb/
sudo cp -r ~/inception-backup/wordpress/* /home/abausa-v/data/wordpress/

# Restart services
make run
```

## Support

For issues or questions:
1. Check the logs as described in the Service Health Checks section
2. Review the DEV_DOC.md for technical details
3. Consult the 42 Inception project subject
4. Contact the project maintainer: abausa-v@student.42madrid.com
