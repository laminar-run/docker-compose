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

## HTTPS Configuration (Optional)

> Note: this can be done with our `start.sh` script.

Prerequisites:
* Ensure that a certificate has been created for the domain name that will be used to access the Laminar platform. Ensure that it is a valid, signed certificate.

Setup:
1. Add the following files to the docker-compose directory:
   * `certs/tls.crt` - the X509 certificate file in PEM format
   * `certs/tls.key` - the private key file in PEM format
2. Uncomment the following lines in the docker-compose.yml file for both the frontend and api services:
   ```yaml
   # volumes:
   #   - ./certs/tls.crt:/app/certs/tls.crt:ro
   #   - ./certs/tls.key:/app/certs/tls.key:ro
   ```

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
