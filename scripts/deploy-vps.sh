#!/bin/bash

# Postiz VPS Deployment Script
# This script automates the deployment of Postiz on a fresh Ubuntu VPS

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root. Please run as a regular user with sudo privileges."
   exit 1
fi

# Configuration
DOMAIN=""
EMAIL=""
DB_PASSWORD=""
REDIS_PASSWORD=""
JWT_SECRET=""

# Function to generate random password
generate_password() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
}

# Welcome message
echo -e "${BLUE}"
echo "=================================================="
echo "    Postiz VPS Deployment Script"
echo "=================================================="
echo -e "${NC}"

# Get user input
read -p "Enter your domain name (e.g., postiz.yourdomain.com): " DOMAIN
read -p "Enter your email for SSL certificate: " EMAIL

if [ -z "$DOMAIN" ] || [ -z "$EMAIL" ]; then
    print_error "Domain and email are required!"
    exit 1
fi

# Generate secure passwords
DB_PASSWORD=$(generate_password)
REDIS_PASSWORD=$(generate_password)
JWT_SECRET=$(generate_password)$(generate_password)

print_status "Generated secure passwords for database and Redis"

# Update system
print_status "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install Docker
print_status "Installing Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    print_success "Docker installed successfully"
else
    print_success "Docker is already installed"
fi

# Install Docker Compose
print_status "Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    print_success "Docker Compose installed successfully"
else
    print_success "Docker Compose is already installed"
fi

# Install Nginx
print_status "Installing Nginx..."
sudo apt install nginx -y
sudo systemctl enable nginx
sudo systemctl start nginx

# Install Certbot
print_status "Installing Certbot for SSL..."
sudo apt install certbot python3-certbot-nginx -y

# Clone repository
print_status "Cloning Postiz repository..."
if [ -d "postiz-app" ]; then
    print_warning "postiz-app directory already exists. Removing it..."
    rm -rf postiz-app
fi

git clone https://github.com/gitroomhq/postiz-app.git
cd postiz-app

# Create production environment file
print_status "Creating production environment configuration..."
cat > .env.production << EOF
# Database Configuration
POSTGRES_DB=postiz
POSTGRES_USER=postiz
POSTGRES_PASSWORD=${DB_PASSWORD}

# Redis Configuration
REDIS_PASSWORD=${REDIS_PASSWORD}

# Application Configuration
NODE_ENV=production
JWT_SECRET=${JWT_SECRET}
FRONTEND_URL=https://${DOMAIN}
NEXT_PUBLIC_BACKEND_URL=https://api.${DOMAIN}
BACKEND_INTERNAL_URL=http://postiz-backend:3000

# Storage Configuration (Update with your Cloudflare R2 credentials)
STORAGE_PROVIDER=local
UPLOAD_DIRECTORY=/app/uploads

# Optional: Email configuration (Add your Resend API key)
# RESEND_API_KEY=your-resend-api-key
# EMAIL_FROM_ADDRESS=noreply@${DOMAIN}
# EMAIL_FROM_NAME=Postiz

# Optional: Social Media API Keys (Add your API keys)
# X_API_KEY=your-twitter-api-key
# X_API_SECRET=your-twitter-api-secret
# LINKEDIN_CLIENT_ID=your-linkedin-client-id
# LINKEDIN_CLIENT_SECRET=your-linkedin-client-secret
EOF

# Get SSL certificate
print_status "Obtaining SSL certificate..."
sudo certbot certonly --nginx -d $DOMAIN -d api.$DOMAIN --email $EMAIL --agree-tos --non-interactive

# Configure Nginx
print_status "Configuring Nginx..."
sudo tee /etc/nginx/sites-available/postiz > /dev/null << EOF
# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name $DOMAIN api.$DOMAIN;
    return 301 https://\$server_name\$request_uri;
}

# Main application
server {
    listen 443 ssl http2;
    server_name $DOMAIN;

    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

    # SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

    location / {
        proxy_pass http://localhost:4200;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header X-Forwarded-Port \$server_port;
    }
}

# API backend
server {
    listen 443 ssl http2;
    server_name api.$DOMAIN;

    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

    # SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header X-Forwarded-Port \$server_port;
    }
}
EOF

# Enable the site
sudo ln -sf /etc/nginx/sites-available/postiz /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx

# Build and start services
print_status "Building and starting Postiz services..."
docker-compose -f docker-compose.production.yaml up -d --build

# Wait for services to start
print_status "Waiting for services to start..."
sleep 30

# Run database migrations
print_status "Running database migrations..."
docker-compose -f docker-compose.production.yaml exec -T postiz-backend-prod pnpm run prisma-db-push

# Create backup script
print_status "Creating backup script..."
sudo tee /usr/local/bin/postiz-backup > /dev/null << 'EOF'
#!/bin/bash
BACKUP_DIR="/var/backups/postiz"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Database backup
docker-compose -f /home/$(whoami)/postiz-app/docker-compose.production.yaml exec -T postiz-postgres-prod pg_dump -U postiz postiz > $BACKUP_DIR/db_backup_$DATE.sql

# Compress old backups
find $BACKUP_DIR -name "*.sql" -mtime +7 -exec gzip {} \;

# Remove backups older than 30 days
find $BACKUP_DIR -name "*.gz" -mtime +30 -delete

echo "Backup completed: $BACKUP_DIR/db_backup_$DATE.sql"
EOF

sudo chmod +x /usr/local/bin/postiz-backup

# Create systemd service for automatic updates
print_status "Setting up automatic SSL renewal..."
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer

# Create update script
print_status "Creating update script..."
tee ~/update-postiz.sh > /dev/null << 'EOF'
#!/bin/bash
cd ~/postiz-app
git pull origin main
docker-compose -f docker-compose.production.yaml up -d --build
docker-compose -f docker-compose.production.yaml exec -T postiz-backend-prod pnpm run prisma-db-push
echo "Postiz updated successfully!"
EOF

chmod +x ~/update-postiz.sh

# Setup firewall
print_status "Configuring firewall..."
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable

# Display completion message
print_success "Deployment completed successfully!"
echo ""
echo "=================================================="
echo "    Deployment Summary"
echo "=================================================="
echo "Domain: https://$DOMAIN"
echo "API: https://api.$DOMAIN"
echo ""
echo "Database Password: $DB_PASSWORD"
echo "Redis Password: $REDIS_PASSWORD"
echo "JWT Secret: $JWT_SECRET"
echo ""
echo "IMPORTANT: Save these credentials securely!"
echo ""
echo "Next Steps:"
echo "1. Visit https://$DOMAIN to access Postiz"
echo "2. Create your admin account"
echo "3. Configure social media integrations in .env.production"
echo "4. Setup Cloudflare R2 for file storage (recommended)"
echo "5. Add email service (Resend) for user notifications"
echo ""
echo "Useful Commands:"
echo "- View logs: docker-compose -f ~/postiz-app/docker-compose.production.yaml logs -f"
echo "- Restart services: docker-compose -f ~/postiz-app/docker-compose.production.yaml restart"
echo "- Update Postiz: ~/update-postiz.sh"
echo "- Backup database: sudo /usr/local/bin/postiz-backup"
echo ""
echo "Support: https://docs.postiz.com"
echo "=================================================="

print_warning "Please reboot the system to ensure all Docker group changes take effect:"
print_warning "sudo reboot"