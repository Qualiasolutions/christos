#!/bin/bash

# Postiz Environment Setup Script
# Quickly generates secure environment variables for production

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Generate secure random string
generate_secret() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-32
}

echo -e "${BLUE}"
echo "=================================================="
echo "    Postiz Environment Setup"
echo "=================================================="
echo -e "${NC}"

# Get user input
read -p "Enter your domain (e.g., postiz.yourdomain.com): " DOMAIN
read -p "Enter your API subdomain (e.g., api.yourdomain.com): " API_DOMAIN

# Generate secrets
JWT_SECRET=$(generate_secret)$(generate_secret)
DB_PASSWORD=$(generate_secret)
REDIS_PASSWORD=$(generate_secret)

# Create production environment file
print_info "Creating production environment file..."

cat > .env.production << EOF
# === Core Configuration ===
NODE_ENV=production
NODE_OPTIONS=--max-old-space-size=2048

# === Database Configuration ===
DATABASE_URL=postgresql://postiz:${DB_PASSWORD}@localhost:5432/postiz
POSTGRES_DB=postiz
POSTGRES_USER=postiz
POSTGRES_PASSWORD=${DB_PASSWORD}

# === Redis Configuration ===
REDIS_URL=redis://:${REDIS_PASSWORD}@localhost:6379
REDIS_PASSWORD=${REDIS_PASSWORD}

# === Security ===
JWT_SECRET=${JWT_SECRET}

# === Application URLs ===
FRONTEND_URL=https://${DOMAIN}
NEXT_PUBLIC_BACKEND_URL=https://${API_DOMAIN}
BACKEND_INTERNAL_URL=http://localhost:3000

# === Storage (Update with your preferred provider) ===
STORAGE_PROVIDER=local
UPLOAD_DIRECTORY=/app/uploads
NEXT_PUBLIC_UPLOAD_STATIC_DIRECTORY=/uploads

# === Email Service (Add your Resend API key) ===
# RESEND_API_KEY=your-resend-api-key
# EMAIL_FROM_ADDRESS=noreply@${DOMAIN}
# EMAIL_FROM_NAME=Postiz

# === Social Media APIs (Add your credentials) ===
# X (Twitter)
# X_API_KEY=your-x-api-key
# X_API_SECRET=your-x-api-secret

# LinkedIn
# LINKEDIN_CLIENT_ID=your-linkedin-client-id
# LINKEDIN_CLIENT_SECRET=your-linkedin-client-secret

# Facebook & Instagram
# FACEBOOK_CLIENT_ID=your-facebook-client-id
# FACEBOOK_CLIENT_SECRET=your-facebook-client-secret

# === Optional Services ===
# OpenAI for AI features
# OPENAI_API_KEY=your-openai-api-key

# Stripe for payments
# STRIPE_SECRET_KEY=your-stripe-secret-key
# STRIPE_PUBLISHABLE_KEY=your-stripe-publishable-key

# Analytics
# PLAUSIBLE_DOMAIN=${DOMAIN}
# POSTHOG_API_KEY=your-posthog-api-key

# Monitoring
# SENTRY_DSN=your-sentry-dsn
EOF

# Create Railway environment file
print_info "Creating Railway environment template..."

cat > .env.railway << EOF
# Railway Environment Variables
# Copy these to your Railway project settings

NODE_ENV=production
NODE_OPTIONS=--max-old-space-size=2048
JWT_SECRET=${JWT_SECRET}
FRONTEND_URL=https://your-app.railway.app
NEXT_PUBLIC_BACKEND_URL=https://your-app.railway.app
BACKEND_INTERNAL_URL=http://localhost:3000
STORAGE_PROVIDER=cloudflare

# Add your Cloudflare R2 credentials
CLOUDFLARE_ACCOUNT_ID=your-account-id
CLOUDFLARE_ACCESS_KEY=your-access-key
CLOUDFLARE_SECRET_ACCESS_KEY=your-secret-key
CLOUDFLARE_BUCKETNAME=your-bucket-name
CLOUDFLARE_BUCKET_URL=https://your-bucket.r2.cloudflarestorage.com/

# Optional: Add social media API keys
# RESEND_API_KEY=your-resend-api-key
# X_API_KEY=your-x-api-key
# X_API_SECRET=your-x-api-secret
# LINKEDIN_CLIENT_ID=your-linkedin-client-id
# LINKEDIN_CLIENT_SECRET=your-linkedin-client-secret
EOF

# Display results
print_success "Environment files created successfully!"
echo ""
echo "=================================================="
echo "    Generated Credentials"
echo "=================================================="
echo "Database Password: ${DB_PASSWORD}"
echo "Redis Password: ${REDIS_PASSWORD}"
echo "JWT Secret: ${JWT_SECRET}"
echo ""
echo "Files created:"
echo "- .env.production (for VPS/Docker deployment)"
echo "- .env.railway (for Railway deployment)"
echo ""
print_warning "IMPORTANT: Save these credentials securely!"
print_warning "Do not commit these files to git!"
echo ""
echo "Next steps:"
echo "1. For Railway: Copy variables from .env.railway to Railway dashboard"
echo "2. For VPS: Use .env.production with docker-compose.production.yaml"
echo "3. Add your social media API credentials to enable integrations"
echo "4. Configure Cloudflare R2 for file storage (recommended)"
echo "=================================================="