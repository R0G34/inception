# Developer Documentation - 42 Inception Project

## Overview

This documentation provides comprehensive technical information for developers working on or extending the 42 Inception project. It covers the architecture, setup, and internals of the Docker-based infrastructure.

## Prerequisites

### Required Software

#### 1. Virtual Machine
- **Requirement**: This project **must** be run inside a Virtual Machine
- **Reason**: Provides isolation and matches 42 evaluation requirements

#### 2. Docker
- **Installation**:
  ```bash
  # Update package index
  sudo apt-get update
  
  # Install Docker
  sudo apt-get install docker.io
  
  # Add user to docker group (to run without sudo)
  sudo usermod -aG docker $USER
  
  # Log out and back in for group changes to take effect
  ```

- **Verification**:
  ```bash
  docker --version
  docker run hello-world
  ```

#### 3. Docker Compose
- **Minimum Version**: Docker Compose 2.0 or higher (included with Docker Desktop)
- **Verification**:
  ```bash
  docker compose version
  ```

## Environment Setup

### Step 1: Configure the .env File

The `.env` file is located in `srcs/.env` and contains all sensitive configuration variables.

### Step 2: Data Directory Setup

The project uses bind mounts to persist data on the host machine.

**Data Directories**:
- MariaDB data: `/home/abausa-v/data/mariadb`
- WordPress files: `/home/abausa-v/data/wordpress`

These directories are automatically created by the Makefile's `build` target. If creating manually:

```bash
mkdir -p /home/abausa-v/data/mariadb
mkdir -p /home/abausa-v/data/wordpress
```

**Permissions**: Ensure the directories are writable by the Docker daemon:

```bash
sudo chown -R $USER:$USER /home/abausa-v/data
chmod -R 755 /home/abausa-v/data
```

### Step 3: Configure /etc/hosts

Add the domain name to your hosts file for local access:

```bash
sudo echo "<VM_IP> abausa-v.42.fr" | sudo tee -a /etc/hosts
```

Or manually edit `/etc/hosts` and add:
```
<VM_IP> abausa-v.42.fr
```

## Building and Launching

### Makefile Targets

The project uses a Makefile to simplify Docker Compose operations.

#### `make all` (or just `make`)
**Purpose**: Complete build and launch sequence

**Actions**:
1. Creates data directories
2. Builds Docker images from Dockerfiles
3. Starts all containers in detached mode

**Command Equivalent**:
```bash
mkdir -p /home/abausa-v/data/mariadb /home/abausa-v/data/wordpress
docker compose -f ./srcs/docker-compose.yml up --build -d
```

**When to Use**: First-time setup or after significant changes to Dockerfiles

#### `make build`
**Purpose**: Build images and start containers

**Actions**: Same as `make all`

#### `make run`
**Purpose**: Start containers without rebuilding

**Actions**: Starts existing containers in detached mode

**Command Equivalent**:
```bash
docker compose -f ./srcs/docker-compose.yml up -d
```

**When to Use**: When images are already built and you just want to start services

#### `make down`
**Purpose**: Stop all running containers

**Actions**: Gracefully stops all containers but preserves volumes

**Command Equivalent**:
```bash
docker compose -f ./srcs/docker-compose.yml down
```

**When to Use**: To stop services temporarily without losing data

#### `make clean`
**Purpose**: Stop containers and remove volumes

**Actions**: Stops containers and removes Docker volumes (but not bind mount data)

**Command Equivalent**:
```bash
docker compose -f ./srcs/docker-compose.yml down -v
```

**When to Use**: When you want to reset volumes but keep host data

#### `make fclean`
**Purpose**: Complete cleanup

**Actions**:
1. Runs `make clean`
2. Removes all Docker system resources (images, containers, cache)
3. Deletes all data from `/home/abausa-v/data/` directories

**Command Equivalent**:
```bash
docker compose -f ./srcs/docker-compose.yml down -v
docker system prune -a -f
sudo rm -rf /home/abausa-v/data/mariadb
sudo rm -rf /home/abausa-v/data/wordpress
```

**⚠️ Warning**: This permanently deletes all data!

#### `make re`
**Purpose**: Complete rebuild

**Actions**: Runs `make down`, `make fclean`, `make build`, and `make run` in sequence

**When to Use**: For a fresh start after major configuration changes

### Docker Compose Commands

For more granular control, use Docker Compose directly:

```bash
# Start services in foreground (see logs)
docker compose -f srcs/docker-compose.yml up

# Build without cache
docker compose -f srcs/docker-compose.yml build --no-cache

# Restart a specific service
docker compose -f srcs/docker-compose.yml restart <service-name>

# View running services
docker compose -f srcs/docker-compose.yml ps

# View logs
docker compose -f srcs/docker-compose.yml logs -f
```

### Build Process Flow

1. **Makefile Execution**: `make all` is called
2. **Directory Creation**: Data directories are created on host
3. **Docker Compose Parse**: `docker-compose.yml` is parsed
4. **Image Building**: Each service's Dockerfile is built:
   - **MariaDB**: Installs MariaDB, copies configuration and entrypoint script
   - **WordPress**: Installs PHP-FPM, WordPress CLI, copies configuration
   - **Nginx**: Installs Nginx, generates SSL certificates, copies configuration
5. **Network Creation**: Docker creates the `inception` bridge network
6. **Volume Setup**: Bind mounts are configured to host directories
7. **Container Launch**: Containers start in dependency order:
   - MariaDB (first)
   - WordPress (after MariaDB)
   - Nginx (after WordPress)
8. **Entrypoint Execution**: Each container runs its entrypoint script:
   - **MariaDB**: Initializes database if first run
   - **WordPress**: Downloads and configures WordPress if first run
   - **Nginx**: Starts web server

## Container Management

### Docker Commands for Managing Containers

#### View Running Containers
```bash
docker ps
```

#### View All Containers (including stopped)
```bash
docker ps -a
```

#### Stop a Specific Container
```bash
docker stop <container-name>
```

#### Start a Specific Container
```bash
docker start <container-name>
```

#### Restart a Container
```bash
docker restart <container-name>
```

#### Remove a Container
```bash
docker rm <container-name>
```

#### Execute Commands in a Running Container
```bash
# Open a shell
docker exec -it <container-name> /bin/sh

# Run a specific command
docker exec <container-name> <command>
```

**Examples**:
```bash
# Access MariaDB
docker exec -it mariadb mysql -u root -p

# Check WordPress files
docker exec -it wordpress ls -la /var/www/html

# Test Nginx configuration
docker exec -it nginx nginx -t
```

#### View Container Resource Usage
```bash
docker stats
```

### Volume Management Commands

#### List Volumes
```bash
docker volume ls
```

#### Inspect a Volume
```bash
docker volume inspect <volume-name>
```

**Example**:
```bash
docker volume inspect mariadb-vol
```

#### Remove a Volume
```bash
docker volume rm <volume-name>
```

**⚠️ Warning**: This deletes all data in the volume!

#### Remove All Unused Volumes
```bash
docker volume prune
```

### Network Inspection Commands

#### List Networks
```bash
docker network ls
```

#### Inspect the Inception Network
```bash
docker network inspect inception
```

This shows:
- Connected containers
- IP addresses
- Network configuration

#### Test Network Connectivity
```bash
# From WordPress container, ping MariaDB
docker exec wordpress ping -c 3 mariadb

# Check if WordPress can connect to MariaDB
docker exec wordpress nc -zv mariadb 3306
```

## Project Structure

### Directory Layout

```
42_inception/
├── Makefile                          # Build automation
├── README.md                         # Project overview
├── USER_DOC.md                       # User documentation
├── DEV_DOC.md                        # This file
└── srcs/
    ├── .env                          # Environment variables (not in git)
    ├── docker-compose.yml            # Service orchestration
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile            # MariaDB image definition
        │   ├── conf/
        │   │   └── my.cnf            # MariaDB configuration
        │   └── tools/
        │       └── entrypoint.sh     # Database initialization script
        ├── wordpress/
        │   ├── Dockerfile            # WordPress image definition
        |   ├── conf/
        │   │   └── www.conf          # WordPress configuration
        │   └── tools/
        │       └── entrypoint.sh     # WordPress installation script
        └── nginx/
            ├── Dockerfile 
            ├── tools/
            │  └── entrypoint.sh      # Nginx installation script
            └── conf/
                └── nginx.conf        # Nginx server configuration
```

### Dockerfile Locations and Purposes

#### 1. MariaDB Dockerfile
**Location**: `srcs/requirements/mariadb/Dockerfile`

**Purpose**: Builds a MariaDB database server

**Key Steps**:
- Base: Debian 12
- Installs MariaDB server and client
- Creates necessary directories with correct permissions
- Copies and makes executable the entrypoint script
- Exposes port 3306

#### 2. WordPress Dockerfile
**Location**: `srcs/requirements/wordpress/Dockerfile`

**Purpose**: Builds a WordPress application server with PHP-FPM

**Key Steps**:
- Base: Debian 12
- Installs PHP 8.2 and required extensions
- Installs WordPress CLI (wp-cli)
- Installs MariaDB client for database communication
- Copies PHP-FPM configuration
- Copies WordPress setup script
- Exposes port 9000 (PHP-FPM)

#### 3. Nginx Dockerfile
**Location**: `srcs/requirements/nginx/Dockerfile`

**Purpose**: Builds an Nginx web server with SSL/TLS

**Key Steps**:
- Base: Debian 12
- Installs Nginx and OpenSSL
- Generates self-signed SSL certificate
- Copies Nginx configuration
- Exposes ports 443 (do not expose 80 : http)
- Runs Nginx in foreground mode

### Configuration Files Locations

- **MariaDB Config**: `srcs/requirements/mariadb/conf/my.cnf`
- **PHP-FPM Config**: `srcs/requirements/wordpress/conf/www.conf`
- **Nginx Config**: `srcs/requirements/nginx/conf/nginx.conf`
- **Environment Variables**: `srcs/.env`
- **Docker Compose**: `srcs/docker-compose.yml`

## Data Persistence

### Volume Strategy

This project uses **bind mounts** instead of Docker-managed volumes for explicit data control.

#### Bind Mount Locations

**MariaDB Data**:
- **Host Path**: `/home/abausa-v/data/mariadb`
- **Container Path**: `/var/lib/mysql`
- **Purpose**: Stores database tables, indexes, and MariaDB system files

**WordPress Data**:
- **Host Path**: `/home/abausa-v/data/wordpress`
- **Container Path**: `/var/www/html`
- **Purpose**: Stores WordPress core files, themes, plugins, and uploads

### How Volumes Work in This Project

1. **Volume Declaration** in `docker-compose.yml`:
   ```yaml
   volumes:
     mariadb_vol:
       name: mariadb-vol
       driver: local
       driver_opts:
         type: none
         o: bind
         device: /home/abausa-v/data/mariadb
   ```

2. **Bind Mount Configuration**:
   - `type: none` with `o: bind` tells Docker to use a bind mount
   - `device:` specifies the host path
   - Data written to `/var/lib/mysql` in the container appears in `/home/abausa-v/data/mariadb` on the host

3. **Benefits**:
   - Data survives container removal (`docker rm`)
   - Easy to backup (just copy host directories)
   - Easy to inspect (navigate to host path)
   - Complies with 42 subject requirements

## Architecture Details

### Services Communication

```
Internet
    ↓ HTTPS (port 443)
┌─────────────────┐
│   Nginx         │ ← Entry Point (Debian 12)
│   Port: 443     │ ← SSL/TLS termination
└────────┬────────┘
         │ FastCGI (port 9000)
         ↓
┌─────────────────┐
│   WordPress     │ ← Application Logic (Debian 12)
│   Port: 9000    │ ← PHP-FPM
└────────┬────────┘
         │ MySQL Protocol (port 3306)
         ↓
┌─────────────────┐
│   MariaDB       │ ← Database (Debian 12)
│   Port: 3306    │ ← Data Storage
└─────────────────┘
```

#### Communication Flow

1. **Client → Nginx**:
   - Protocol: HTTPS (TLS 1.2/1.3)
   - Port: 443 (exposed to host)
   - Purpose: Accepts web requests

2. **Nginx → WordPress**:
   - Protocol: FastCGI
   - Port: 9000 (internal Docker network)
   - Connection: `fastcgi_pass wordpress:9000;`
   - Purpose: Forwards PHP requests to WordPress

3. **WordPress → MariaDB**:
   - Protocol: MySQL protocol
   - Port: 3306 (internal Docker network)
   - Connection: `--dbhost="mariadb"` in `.env`
   - Purpose: Database queries and data persistence

### Network Configuration

**Network Name**: `inception`

**Driver**: `bridge` (default Docker network driver)

**Configuration** in `docker-compose.yml`:
```yaml
networks:
  inception:
    driver: bridge
```

#### Bridge Network Characteristics

- **Isolation**: Containers on this network are isolated from host network and other Docker networks
- **DNS**: Docker provides built-in DNS, allowing containers to communicate using service names (e.g., `mariadb`, `wordpress`)
- **IP Assignment**: Docker automatically assigns IP addresses from the network's subnet
- **Communication**: All three containers can communicate with each other

#### Network Inspection

```bash
docker network inspect inception
```

**Key Information**:
- Subnet and Gateway
- Connected containers and their IPs
- Network configuration options

### Port Mappings

#### Exposed Ports (to host machine)

- **443:443** → Nginx HTTPS (accessible from host)

#### Internal Ports (within Docker network only)

- **3306** → MariaDB (not exposed to host, accessible only by WordPress)
- **9000** → WordPress PHP-FPM (not exposed to host, accessible only by Nginx)

**Security Benefit**: Database and application logic are not directly accessible from outside the Docker network.

### SSL/TLS Configuration

#### Certificate Generation

**Location**: Nginx Dockerfile

**Command**:
```bash
openssl req -x509 -nodes \
  -out /etc/nginx/ssl/inception.crt \
  -keyout /etc/nginx/ssl/inception.key \
  -subj "/C=FR/ST=IDF/L=Paris/O=42/OU=42/CN=abausa-v.42.fr/UID=abausa-v"
```

**Certificate Details**:
- Type: Self-signed X.509 certificate
- Algorithm: RSA (default)
- No passphrase (`-nodes` flag)
- Subject: CN=abausa-v.42.fr

#### Nginx SSL Configuration

**Location**: `srcs/requirements/nginx/conf/nginx.conf`

```nginx
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    
    ssl_certificate /etc/nginx/ssl/inception.crt;
    ssl_certificate_key /etc/nginx/ssl/inception.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    
    # ... rest of configuration
}
```

**Key Points**:
- Listens on port 443 for both IPv4 and IPv6
- Enforces TLS 1.2 and 1.3 only (no older, insecure protocols)
- Self-signed certificate (for development/testing)

**Production Consideration**: For production, replace with a certificate from a trusted Certificate Authority (Let's Encrypt, etc.)

## Development Workflow

### Making Changes

1. **Modify Dockerfiles or configurations**
2. **Rebuild affected services**:
   ```bash
   docker compose -f srcs/docker-compose.yml build <service-name>
   ```
3. **Restart the service**:
   ```bash
   docker compose -f srcs/docker-compose.yml up -d <service-name>
   ```

### Debugging

#### View Real-Time Logs
```bash
docker compose -f srcs/docker-compose.yml logs -f
```

#### Access Container Shell
```bash
docker exec -it <container-name> /bin/sh
```

#### Test Network Connectivity
```bash
# From WordPress to MariaDB
docker exec wordpress nc -zv mariadb 3306

# From Nginx to WordPress
docker exec nginx nc -zv wordpress 9000
```

#### Check Environment Variables
```bash
docker exec <container-name> env
```

### Testing Changes

1. **Syntax Validation**:
   - Nginx: `docker exec nginx nginx -t`
   - PHP: `docker exec wordpress php -v`
   - MariaDB: `docker exec mariadb mysqld --version`

2. **Service Health**:
   ```bash
   docker ps  # All should show "Up"
   ```

3. **Functional Testing**:
   - Access https://abausa-v.42.fr
   - Login to WordPress admin
   - Create a test post
   - Verify data persists after `make down` and `make run`

## Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [WordPress CLI Documentation](https://developer.wordpress.org/cli/)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [MariaDB Documentation](https://mariadb.com/kb/en/)

## Support

For technical issues or questions:
- Review container logs: `docker logs <container-name>`
- Check Docker network: `docker network inspect inception`
- Consult the USER_DOC.md for operational guidance
- Contact: abausa-v@student.42.fr
