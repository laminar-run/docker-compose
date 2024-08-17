# Docker Compose
This repository contains the necessary files to deploy Laminar on-premises using Docker Compose.

## Quick Start
### Start Laminar
To quickly set up and start Laminar, run:
```bash
make start
```

### Reset Laminar
To reset Laminar and start from scratch, run:
```bash
make reset
```

### Update Laminar
To update Laminar to the latest version, run:
```bash
make update
```

## Prerequisites
### Required
* Docker token for the Laminar private registry (supplied by Laminar).
* Ubuntu >= 20.04 or equivalent Linux distribution
* Docker >= 20.10.7
* Docker-compose >= 1.29.2
* 4 vCPU
* 16 GB RAM
* 32 GB disk space

### Optional
* (Optional) An S3 bucket for backups and storage (configuration details provided separately)

## Service Access
After deployment, services are accessible at the following URLs (replace `localhost` with your domain or IP address if different):

* Frontend: http://localhost:3000
* API: http://localhost:8080
* Keycloak: http://localhost:8180
* Temporal: http://localhost:7233
* Temporal UI: http://localhost:8081

## Environment Variables
Environment variables are automatically generated and stored in the `.env` file. Sensitive information is stored separately in `laminar_secrets.txt`.

## Customization
To customize the deployment, modify the `docker-compose.yml` file as needed.

### Troubleshooting
If you encounter issues with container names already in use, you can remove all stopped containers with:
```bash
docker container prune -f
```
For other issues, please consult the Laminar documentation or contact support.

### Backups
> **Note:** This feature is not yet implemented.

### Updating
To update your Laminar deployment:
1. Pull the latest changes from this repository
2. Run the update script:
```bash
./scripts/update-laminar.sh
```
This script will pull the latest Docker images and restart the services.

### Security Considerations
This setup exposes services directly without a reverse proxy. For production environments, consider:
1. Implementing a reverse proxy (like Nginx or Traefik) for SSL termination and additional security.
2. Configuring firewalls to restrict access to necessary ports only.
3. Using strong passwords and regularly updating them.
4. Keeping all components updated to the latest versions.

### Support
For additional support or questions, please contact Laminar support at connect@laminar.run.