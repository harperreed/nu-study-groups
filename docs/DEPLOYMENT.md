# Nu Application - Production Deployment Guide

This guide covers deploying the Nu calendar application to production using Docker and PostgreSQL.

## Prerequisites

- Docker Engine 20.10 or higher
- Docker Compose V2
- At least 2GB of available RAM
- A Google OAuth application configured for production

## Quick Start

```bash
# 1. Clone the repository
git clone <repository-url>
cd nu

# 2. Set up environment variables
cp .env.production.example .env.production
# Edit .env.production with your actual values

# 3. Generate a secret key base
docker run --rm ruby:3.2.2-slim bash -c "gem install rails && rails secret"
# Copy the output to SECRET_KEY_BASE in .env.production

# 4. Build and start services
docker-compose -f docker-compose.prod.yml up -d

# 5. Check service status
docker-compose -f docker-compose.prod.yml ps

# 6. View logs
docker-compose -f docker-compose.prod.yml logs -f
```

The application will be available at `http://localhost:3000` (or the port specified in your `.env.production`).

## Environment Variables Setup

### Required Variables

Create a `.env.production` file based on `.env.production.example`:

1. **Database Configuration**
   ```bash
   POSTGRES_USER=nu
   POSTGRES_PASSWORD=<generate-secure-password>
   POSTGRES_DB=nu_production
   QUEUE_POSTGRES_DB=nu_queue_production
   ```

2. **Rails Secret**
   ```bash
   # Generate with:
   docker run --rm ruby:3.2.2-slim bash -c "gem install rails && rails secret"

   SECRET_KEY_BASE=<your-generated-secret>
   ```

3. **Google OAuth**
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Create a new project or select an existing one
   - Enable the Google+ API
   - Create OAuth 2.0 credentials
   - Add authorized redirect URI: `http://your-domain.com/auth/google_oauth2/callback`
   - Copy the Client ID and Client Secret:
   ```bash
   GOOGLE_CLIENT_ID=<your-client-id>
   GOOGLE_CLIENT_SECRET=<your-client-secret>
   ```

### Optional Variables

```bash
# Application port (default: 3000)
PORT=3000

# Application hostname (if behind reverse proxy)
RAILS_HOSTNAME=yourdomain.com
```

## Database Setup

The database is automatically initialized on first startup. The web service runs `rails db:prepare` which:
1. Creates the databases if they don't exist
2. Loads the schema
3. Runs any pending migrations
4. Seeds the database (if configured)

### Manual Database Operations

```bash
# Run migrations
docker-compose -f docker-compose.prod.yml run --rm web bundle exec rails db:migrate

# Rollback migrations
docker-compose -f docker-compose.prod.yml run --rm web bundle exec rails db:rollback

# Seed the database
docker-compose -f docker-compose.prod.yml run --rm web bundle exec rails db:seed

# Reset the database (CAUTION: destroys all data!)
docker-compose -f docker-compose.prod.yml run --rm web bundle exec rails db:reset

# Access Rails console
docker-compose -f docker-compose.prod.yml run --rm web bundle exec rails console
```

## Building the Production Image

The production image is built automatically by `docker-compose`, but you can build it manually:

```bash
# Build the production image
docker build --target production -t nu:production .

# Build with no cache (if dependencies changed)
docker build --target production --no-cache -t nu:production .
```

## Managing Services

### Starting Services

```bash
# Start all services in detached mode
docker-compose -f docker-compose.prod.yml up -d

# Start specific services
docker-compose -f docker-compose.prod.yml up -d web worker

# Start with build (if code changed)
docker-compose -f docker-compose.prod.yml up -d --build
```

### Stopping Services

```bash
# Stop all services
docker-compose -f docker-compose.prod.yml down

# Stop and remove volumes (CAUTION: destroys database data!)
docker-compose -f docker-compose.prod.yml down -v
```

### Viewing Logs

```bash
# All services
docker-compose -f docker-compose.prod.yml logs -f

# Specific service
docker-compose -f docker-compose.prod.yml logs -f web
docker-compose -f docker-compose.prod.yml logs -f worker
docker-compose -f docker-compose.prod.yml logs -f db

# Last 100 lines
docker-compose -f docker-compose.prod.yml logs --tail=100
```

### Checking Service Health

```bash
# View service status
docker-compose -f docker-compose.prod.yml ps

# Check health endpoint
curl http://localhost:3000/up

# View container details
docker-compose -f docker-compose.prod.yml exec web bundle exec rails about
```

## Production Deployment Architecture

The production setup consists of four services:

1. **db** - PostgreSQL database for application data
   - Port: 5432 (internal only)
   - Volume: `postgres_data`
   - Health check: `pg_isready`

2. **queue_db** - PostgreSQL database for Solid Queue
   - Port: 5432 (internal only)
   - Volume: `queue_postgres_data`
   - Health check: `pg_isready`

3. **web** - Rails application server
   - Port: 3000 (exposed)
   - Runs Puma web server
   - Health check: `/up` endpoint
   - Serves static assets

4. **worker** - Solid Queue background job processor
   - No exposed ports
   - Processes background jobs
   - Handles calendar update tasks

## Updating the Application

```bash
# 1. Pull latest code
git pull origin main

# 2. Rebuild and restart services
docker-compose -f docker-compose.prod.yml up -d --build

# 3. Run any new migrations
docker-compose -f docker-compose.prod.yml exec web bundle exec rails db:migrate

# 4. Check logs
docker-compose -f docker-compose.prod.yml logs -f
```

## Data Persistence

Data is persisted in Docker volumes:

- `postgres_data` - Application database
- `queue_postgres_data` - Queue database

### Backing Up Data

```bash
# Backup application database
docker-compose -f docker-compose.prod.yml exec db pg_dump -U nu nu_production > backup_$(date +%Y%m%d).sql

# Backup queue database
docker-compose -f docker-compose.prod.yml exec queue_db pg_dump -U nu nu_queue_production > queue_backup_$(date +%Y%m%d).sql
```

### Restoring Data

```bash
# Restore application database
cat backup_20241118.sql | docker-compose -f docker-compose.prod.yml exec -T db psql -U nu nu_production

# Restore queue database
cat queue_backup_20241118.sql | docker-compose -f docker-compose.prod.yml exec -T queue_db psql -U nu nu_queue_production
```

## Performance Tuning

### Resource Limits

Add resource limits to `docker-compose.prod.yml` if needed:

```yaml
services:
  web:
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 1G
        reservations:
          memory: 512M
```

### Database Tuning

For production workloads, consider tuning PostgreSQL:

```bash
# Edit postgresql.conf in the container
docker-compose -f docker-compose.prod.yml exec db vi /var/lib/postgresql/data/postgresql.conf

# Recommended settings for small to medium deployments:
# shared_buffers = 256MB
# effective_cache_size = 1GB
# maintenance_work_mem = 64MB
# checkpoint_completion_target = 0.9
# wal_buffers = 16MB
# default_statistics_target = 100
# random_page_cost = 1.1
# work_mem = 4MB
# min_wal_size = 1GB
# max_wal_size = 4GB
```

## Troubleshooting

### Web Service Won't Start

1. **Check logs:**
   ```bash
   docker-compose -f docker-compose.prod.yml logs web
   ```

2. **Common issues:**
   - Missing `SECRET_KEY_BASE` - Generate one with `rails secret`
   - Database connection failed - Check DATABASE_URL and db service health
   - Port already in use - Change PORT in `.env.production`

### Database Connection Errors

1. **Check database health:**
   ```bash
   docker-compose -f docker-compose.prod.yml ps db
   docker-compose -f docker-compose.prod.yml logs db
   ```

2. **Test connection:**
   ```bash
   docker-compose -f docker-compose.prod.yml exec db psql -U nu nu_production -c "SELECT 1;"
   ```

3. **Verify credentials:**
   - Ensure POSTGRES_USER, POSTGRES_PASSWORD match in both db service and DATABASE_URL

### Worker Not Processing Jobs

1. **Check worker logs:**
   ```bash
   docker-compose -f docker-compose.prod.yml logs worker
   ```

2. **Verify queue database:**
   ```bash
   docker-compose -f docker-compose.prod.yml exec queue_db psql -U nu nu_queue_production -c "\dt"
   ```

3. **Check job queue:**
   ```bash
   docker-compose -f docker-compose.prod.yml run --rm web bundle exec rails console
   # In console:
   SolidQueue::Job.count
   SolidQueue::Job.failed.count
   ```

### Assets Not Loading

1. **Check asset precompilation:**
   ```bash
   docker-compose -f docker-compose.prod.yml exec web ls -la public/assets
   ```

2. **Rebuild with fresh assets:**
   ```bash
   docker-compose -f docker-compose.prod.yml build --no-cache web
   docker-compose -f docker-compose.prod.yml up -d
   ```

### High Memory Usage

1. **Check resource usage:**
   ```bash
   docker stats
   ```

2. **Restart services:**
   ```bash
   docker-compose -f docker-compose.prod.yml restart web worker
   ```

## Security Considerations

1. **Change default passwords** - Never use default passwords in production
2. **Use strong SECRET_KEY_BASE** - Generate with `rails secret`
3. **Enable HTTPS** - Use a reverse proxy (nginx, Caddy, Traefik) with SSL
4. **Regular updates** - Keep Docker images and gems up to date
5. **Backup regularly** - Automate database backups
6. **Monitor logs** - Set up log aggregation and monitoring
7. **Firewall rules** - Only expose necessary ports (3000 for web)
8. **Non-root user** - The Dockerfile already uses a non-root user

## Reverse Proxy Setup (Optional)

For production, it's recommended to use a reverse proxy like nginx:

```nginx
# /etc/nginx/sites-available/nu
server {
    listen 80;
    server_name yourdomain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

For HTTPS with Let's Encrypt:
```bash
sudo certbot --nginx -d yourdomain.com
```

## Monitoring and Alerts

Consider setting up monitoring for:
- Application uptime (via `/up` endpoint)
- Database health
- Worker job processing
- Memory and CPU usage
- Disk space

Tools you can integrate:
- Prometheus + Grafana
- New Relic
- Datadog
- Sentry for error tracking

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review application logs
3. Consult the Rails guides: https://guides.rubyonrails.org/
4. Check Docker documentation: https://docs.docker.com/

## License

[Your license information here]
