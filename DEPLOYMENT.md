# Postiz Deployment Guide

Complete guide for deploying Postiz to production environments.

## 🚀 Quick Start: Railway Deployment (Recommended)

Railway is the easiest and most cost-effective way to deploy Postiz with minimal configuration.

### Prerequisites
- GitHub account with the Postiz repository
- Railway account (free tier available)
- Domain name (optional, Railway provides subdomains)

### Step 1: Prepare Repository
```bash
# Make sure all production files are committed
git add .
git commit -m "Add production configuration"
git push origin main
```

### Step 2: Deploy to Railway
1. **Connect Repository**
   - Go to [Railway](https://railway.app)
   - Click "Start a New Project"
   - Select "Deploy from GitHub repo"
   - Choose your Postiz repository

2. **Configure Services**
   Railway will automatically detect the `railway.toml` configuration and set up:
   - Main application service
   - PostgreSQL database
   - Redis cache

3. **Set Environment Variables**
   In Railway dashboard, add these required variables:
   ```
   NODE_ENV=production
   JWT_SECRET=your-super-secure-jwt-secret-minimum-32-characters
   FRONTEND_URL=https://your-app.railway.app
   NEXT_PUBLIC_BACKEND_URL=https://your-app.railway.app
   STORAGE_PROVIDER=cloudflare
   CLOUDFLARE_ACCOUNT_ID=your-account-id
   CLOUDFLARE_ACCESS_KEY=your-access-key
   CLOUDFLARE_SECRET_ACCESS_KEY=your-secret-key
   CLOUDFLARE_BUCKETNAME=your-bucket-name
   CLOUDFLARE_BUCKET_URL=https://your-bucket.r2.cloudflarestorage.com/
   ```

4. **Add Optional Variables**
   ```
   RESEND_API_KEY=your-resend-api-key
   OPENAI_API_KEY=your-openai-api-key
   X_API_KEY=your-twitter-api-key
   X_API_SECRET=your-twitter-api-secret
   LINKEDIN_CLIENT_ID=your-linkedin-client-id
   LINKEDIN_CLIENT_SECRET=your-linkedin-client-secret
   ```

### Step 3: Database Setup
Railway automatically provisions PostgreSQL and Redis. The connection URLs are automatically set as environment variables.

### Step 4: Deploy
1. Railway automatically deploys on every push to main branch
2. Initial deployment takes 5-10 minutes
3. Check deployment logs for any issues
4. Visit your Railway URL to access Postiz

### Step 5: Custom Domain (Optional)
1. In Railway dashboard, go to Settings → Domains
2. Add your custom domain
3. Update DNS records as instructed
4. Update `FRONTEND_URL` and `NEXT_PUBLIC_BACKEND_URL` environment variables

## 🐳 Docker VPS Deployment

For more control and potentially lower costs, deploy on a VPS using Docker.

### Prerequisites
- VPS with Docker and Docker Compose installed
- Domain name with DNS configured
- SSL certificate (Let's Encrypt recommended)

### Step 1: Prepare VPS
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Reboot to apply group changes
sudo reboot
```

### Step 2: Clone Repository
```bash
git clone https://github.com/gitroomhq/postiz-app.git
cd postiz-app
```

### Step 3: Configure Environment
```bash
# Copy production environment template
cp .env.production.example .env.production

# Edit environment variables
nano .env.production

# Set required variables:
POSTGRES_DB=postiz
POSTGRES_USER=postiz
POSTGRES_PASSWORD=your-secure-db-password
REDIS_PASSWORD=your-secure-redis-password
JWT_SECRET=your-super-secure-jwt-secret
FRONTEND_URL=https://your-domain.com
NEXT_PUBLIC_BACKEND_URL=https://api.your-domain.com
```

### Step 4: SSL Certificate Setup
```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx -y

# Get SSL certificate
sudo certbot certonly --standalone -d your-domain.com -d api.your-domain.com
```

### Step 5: Deploy with Docker Compose
```bash
# Build and start services
docker-compose -f docker-compose.production.yaml up -d

# Check logs
docker-compose -f docker-compose.production.yaml logs -f

# Run database migrations
docker-compose -f docker-compose.production.yaml exec postiz-backend-prod pnpm run prisma-db-push
```

### Step 6: Configure Nginx (Reverse Proxy)
Create `/etc/nginx/sites-available/postiz`:
```nginx
server {
    listen 80;
    server_name your-domain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name your-domain.com;

    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;

    location / {
        proxy_pass http://localhost:4200;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

server {
    listen 443 ssl http2;
    server_name api.your-domain.com;

    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Enable the site:
```bash
sudo ln -s /etc/nginx/sites-available/postiz /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

## 🔧 Other Deployment Options

### DigitalOcean App Platform
1. Connect GitHub repository
2. Use `Dockerfile.production` for container builds
3. Add PostgreSQL and Redis managed databases
4. Configure environment variables

### Render
1. Connect GitHub repository
2. Create Web Service with Docker
3. Add PostgreSQL and Redis services
4. Configure environment variables

### AWS/Google Cloud
1. Use container services (ECS, Cloud Run)
2. Set up managed databases (RDS, Cloud SQL)
3. Configure Redis (ElastiCache, Memorystore)
4. Use load balancers for traffic distribution

## 📊 Monitoring & Maintenance

### Health Checks
```bash
# Check service status
curl -f https://your-domain.com/
curl -f https://api.your-domain.com/

# Check database connectivity
docker-compose -f docker-compose.production.yaml exec postiz-postgres-prod pg_isready

# Check Redis
docker-compose -f docker-compose.production.yaml exec postiz-redis-prod redis-cli ping
```

### Backup Strategy
```bash
# Database backup
docker-compose -f docker-compose.production.yaml exec postiz-postgres-prod pg_dump -U postiz postiz > backup_$(date +%Y%m%d_%H%M%S).sql

# Redis backup
docker-compose -f docker-compose.production.yaml exec postiz-redis-prod redis-cli BGSAVE
```

### Updates
```bash
# Pull latest changes
git pull origin main

# Rebuild and restart services
docker-compose -f docker-compose.production.yaml up -d --build

# Run any new migrations
docker-compose -f docker-compose.production.yaml exec postiz-backend-prod pnpm run prisma-db-push
```

## 🔒 Security Checklist

- [ ] Use strong passwords for database and Redis
- [ ] Enable SSL/TLS for all connections
- [ ] Configure firewall to allow only necessary ports
- [ ] Regularly update dependencies and system packages
- [ ] Monitor logs for suspicious activity
- [ ] Set up rate limiting
- [ ] Use environment variables for all secrets
- [ ] Enable database connection encryption
- [ ] Configure CORS properly

## 💰 Cost Estimates

### Railway (Recommended for most users)
- **Hobby Plan**: $5/month per service
- **Pro Plan**: $20/month per service
- **Estimated Total**: $20-50/month depending on usage

### VPS Deployment
- **Small VPS**: $5-10/month (1-2GB RAM)
- **Medium VPS**: $15-25/month (4-8GB RAM)
- **Large VPS**: $40-80/month (8-16GB RAM)

### Enterprise Options
- AWS/GCP: $100-500/month depending on scale
- Dedicated servers: $50-200/month

## 🚨 Troubleshooting

### Common Issues

**Build Failures**
- Check Node.js version (must be 20.x)
- Ensure pnpm version is 10.6.1
- Verify environment variables are set

**Database Connection Issues**
- Check DATABASE_URL format
- Verify database service is running
- Check network connectivity

**Memory Issues**
- Increase NODE_OPTIONS max heap size
- Use at least 2GB RAM for production
- Monitor resource usage

**Social Platform Integration Issues**
- Verify OAuth app configurations
- Check API key permissions
- Ensure callback URLs are correct

### Getting Help
- Check the logs: `docker-compose logs -f`
- Review environment variables
- Test individual services
- Check Railway/hosting platform status pages
- Consult the [Postiz documentation](https://docs.postiz.com)

## 🎉 Success!

Once deployed, you can:
1. Visit your domain to access Postiz
2. Create your admin account
3. Configure social media integrations
4. Start scheduling posts across 14+ platforms!

Enjoy your self-hosted social media management platform! 🚀