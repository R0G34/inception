# Inception - 42 Project  
*This project has been created as part of the 42 curriculum by aohssine.*

## Description

Inception is a system administration project designed to deepen understanding of Docker virtualization technology. The core objective is to virtualize several Docker images by creating them within a personal virtual machine. Instead of relying on ready-made images, the project requires building a custom infrastructure from scratch using Dockerfiles for each service.




The project involves setting up a small, resilient infrastructure composed of distinct services, each running in a dedicated container to mimic a microservices architecture.


### Main Design Choices
- Base Image: The infrastructure is built upon Alpine Linux. This choice aligns with the requirement to use either Alpine or Debian for performance reasons. Alpine was selected for its extremely lightweight footprint (approx. 5MB) and security-focused design.


- Orchestration: Docker Compose is used to manage the multi-container application, defining services, networks, and volumes in a single YAML file.


- Security: NGINX is configured as the sole entry point, strictly enforcing TLSv1.2 or TLSv1.3 encryption for all external access.


- Persistence: Custom entrypoint scripts are utilized to handle "first-run" logic, ensuring database tables and configuration files are only generated when they do not already exist.

### Technical Comparisons

#### Virtual Machines vs Docker
- Virtual Machines (VMs): A VM emulates an entire physical computer, including a full guest operating system (OS) running on top of a hypervisor. This provides strong isolation but is resource-heavy because each VM runs its own full kernel.


- Docker Containers: Containers share the host machine's OS kernel but isolate the application processes in user space. This makes them significantly lighter, faster to start, and more efficient than VMs. In this project, Docker is used inside a VM, creating a nested virtualization layer.


### Secrets vs Environment Variables

- Environment Variables: Key-value pairs passed to containers at runtime, often loaded from .env files. They are simple to configure but can expose sensitive data (like passwords) in logs or process lists if not handled carefully. This project mandates their use for configuration.


- Docker Secrets: A secure mechanism for managing sensitive data. Secrets are encrypted at rest and mounted as files (e.g., in /run/secrets/) only into the containers that specifically need them. While secrets are recommended for confidential data, environment variables are the mandatory minimum for this assignment.

### Docker Network vs Host Network
- Docker Network (Bridge): Creates an isolated virtual network where containers communicate by name (e.g., WordPress connecting to mariadb:3306). This provides security by isolating internal traffic from the outside world. The project requires a dedicated Docker network to connect the containers.

- Host Network: The container shares the host’s networking namespace directly, using the host's IP and ports. This improves performance but breaks isolation and can cause port conflicts. The use of --network host is explicitly forbidden in Inception.

### Docker Volumes vs Bind Mounts
- Docker Volumes: Storage areas managed entirely by Docker (usually in /var/lib/docker/volumes/). They are the standard for data persistence but are hidden deep in the system files.


- Bind Mounts: These map a specific user-defined directory on the host machine (e.g., /home/login/data/) to a path inside the container. This project requires bind mounts so that the database and website files are stored in a specific, accessible location on the host VM.

## Instructions

### Prerequisites

- This project must be run inside a Virtual Machine.
- Ensure Docker and Docker Compose are installed.
- You need root/sudo privileges to create directories and manage Docker.

### Installation & Configuration

1. **Clone the repository:**
   ```bash
   git clone https://github.com/OhssineAbdelfatah/42_inception.git
   cd 42_inception
   ```

2. **Configure environment variables:**
   - Create or edit the `.env` file in the `srcs` directory with your credentials:
     - Database credentials (root password, database name, user, password)
     - WordPress configuration (database host, admin credentials, site URL)
     - Domain name (e.g., `login.42.fr`)

3. **Update paths (if necessary):**
   - The Makefile and docker-compose.yml use `/home/aohssine/data/` as the default path for bind mounts.
   - Update these paths to match your VM username (e.g., `/home/your-login/data/`).

### Compilation & Execution

**Build and run the infrastructure:**
```bash
make
```
This command will:
- Create the necessary directories for data persistence
- Build all Docker images from Dockerfiles
- Start all containers in detached mode

**Alternative commands:**
- `make build` - Build and start containers
- `make run` - Start existing containers
- `make down` - Stop all containers
- `make clean` - Stop containers and remove volumes
- `make fclean` - Complete cleanup (removes containers, images, and data)
- `make re` - Rebuild everything from scratch

### Access

Once the infrastructure is running:
- Access the WordPress site via HTTPS at: `https://your-domain.42.fr` (using the domain you configured in the `.env` file)
- Ensure your domain is properly configured in your `/etc/hosts` file or DNS

### Verification

Check that all containers are running:
```bash
docker ps
```

You should see three containers: `nginx`, `wordpress`, and `mariadb`.

## Resources

### Documentation & References

- **Docker Official Documentation**: [https://docs.docker.com/](https://docs.docker.com/)
  - Comprehensive guide on Docker concepts, Dockerfile syntax, and best practices
  
- **Docker Compose Documentation**: [https://docs.docker.com/compose/](https://docs.docker.com/compose/)
  - Reference for multi-container orchestration and compose file syntax

- **Alpine Linux**: [https://alpinelinux.org/](https://alpinelinux.org/)
  - Official documentation for the base image used in this project

- **NGINX Documentation**: [https://nginx.org/en/docs/](https://nginx.org/en/docs/)
  - Configuration guides for web server and SSL/TLS setup

- **MariaDB Documentation**: [https://mariadb.com/kb/en/documentation/](https://mariadb.com/kb/en/documentation/)
  - Database server setup and configuration references

- **WordPress Documentation**: [https://wordpress.org/support/](https://wordpress.org/support/)
  - Official WordPress installation and configuration guides
