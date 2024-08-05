# Docker Compose

This repository contains the necessary files to deploy Laminar on-premises using Docker Compose.

## Quick Start

To quickly set up and start Laminar, run:

```bash
./start.sh
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

## HTTPS Configuration

HTTPS is enabled by default using Nginx. The `start.sh` script generates self-signed certificates for development purposes. For production use, replace the certificates in the certs directory:

`certs/tls.crt` - the X509 certificate file in PEM format
`certs/tls.key` - the private key file in PEM format

## Service Access

After deployment, services are accessible at the following URLs:

* Frontend: https://app.localhost
* API: https://api.localhost
* Keycloak: https://keycloak.localhost
* Temporal UI: https://temporal.localhost

## Environment Variables

Environment variables are automatically generated and stored in the `.env` file. Sensitive information is stored separately in `laminar_secrets.txt`.

## Customization

To customize the deployment, modify the `docker-compose.yml` and `nginx.conf` files as needed.

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

### Support

For additional support or questions, please contact Laminar support at connect@laminar.run.
