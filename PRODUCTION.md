# Production Deployment Guide for Dodo Payments

This guide outlines how to deploy Dodo Payments in a production environment using Docker and Docker Compose.

## Prerequisites

- A Linux server with Docker and Docker Compose installed
- Sufficient disk space for the database and application
- Open port 8080 (or configure as needed)

## Production Setup Steps

1. **Clone the repository**

```bash
git clone https://your-repository-url.git
cd dodo-payments
```

2. **Create environment file**

```bash
cp .env.template .env
```

Edit the `.env` file and set secure values for:

- `POSTGRES_PASSWORD`: Choose a strong password
- `JWT_SECRET`: Set a unique, secure key or provide a jwt_secret.txt file

3. **Deploy with Docker Compose**

For production deployment:

```bash
docker-compose -f docker-compose.prod.yml up -d
```

4. **Verify deployment**

Check that all services are running:

```bash
docker-compose -f docker-compose.prod.yml ps
```

Test the API:

```bash
curl http://localhost:8080/health
```

## Maintenance

### Backup Database

Run the backup script:

```bash
./backup-db.sh
```

Backups will be saved in the `./backups` directory.

### Restore Database

To restore from a backup:

```bash
./restore-db.sh ./backups/your-backup-file.sql
```

### Updating the Application

Pull the latest changes and rebuild:

```bash
git pull
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml up -d --build
```

### Logs

View application logs:

```bash
docker-compose -f docker-compose.prod.yml logs -f app
```

### Monitoring

Set up monitoring using Docker's built-in health checks:

```bash
docker inspect --format "{{json .State.Health }}" dodo-payments_app_1
```

## Security Considerations

1. Always use strong passwords for the database
2. Generate a unique JWT secret for each deployment
3. Consider setting up a reverse proxy (like Nginx) with SSL
4. Regularly update the Docker images
5. Implement regular database backups
6. Consider using Docker secrets for sensitive information

## Scaling

For higher loads, consider:

1. Setting up a load balancer
2. Increasing the database resources
3. Implementing database replication
4. Using container orchestration like Kubernetes

## Troubleshooting

- **Database connection issues**: Check DB container health and credentials
- **Application errors**: Check application logs
- **Performance issues**: Monitor resource usage and consider scaling
