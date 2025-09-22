#!/bin/bash

# Railway Automated Setup Script for Postiz
# This script configures all environment variables for Railway deployment

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

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

# Generate secure JWT secret
JWT_SECRET=$(node -e "console.log(require('crypto').randomBytes(32).toString('base64').replace(/[=+/]/g, '').slice(0, 64))")

echo -e "${BLUE}"
echo "=================================================="
echo "    Railway Automated Setup for Postiz"
echo "=================================================="
echo -e "${NC}"

print_status "Generated secure JWT secret: ${JWT_SECRET}"

# Login to Railway (if not already logged in)
print_status "Logging into Railway..."
if ! railway whoami &>/dev/null; then
    print_warning "Please login to Railway first:"
    railway login
fi

# Link to project
print_status "Linking to Railway project..."
railway link

# Add PostgreSQL database
print_status "Adding PostgreSQL database..."
railway add --database postgresql || print_warning "PostgreSQL database may already exist"

# Add Redis database
print_status "Adding Redis database..."
railway add --database redis || print_warning "Redis database may already exist"

# Set environment variables for all services
print_status "Setting up environment variables..."

# Core variables for all services
CORE_VARS=(
    "NODE_ENV=production"
    "NODE_OPTIONS=--max-old-space-size=2048"
    "JWT_SECRET=${JWT_SECRET}"
)

# URL variables (we'll update these after deployment)
URL_VARS=(
    "FRONTEND_URL=https://postiz-frontend-production.up.railway.app"
    "NEXT_PUBLIC_BACKEND_URL=https://postiz-backend-production.up.railway.app"
    "BACKEND_INTERNAL_URL=http://localhost:3000"
)

# Storage variables
STORAGE_VARS=(
    "STORAGE_PROVIDER=local"
    "UPLOAD_DIRECTORY=/app/uploads"
    "NEXT_PUBLIC_UPLOAD_STATIC_DIRECTORY=/uploads"
)

# Function to set variables for a service
set_service_vars() {
    local service_name=$1
    shift
    local vars=("$@")

    print_status "Setting variables for ${service_name}..."

    for var in "${vars[@]}"; do
        railway variables --service "${service_name}" set "${var}" || print_error "Failed to set ${var} for ${service_name}"
    done
}

# Set variables for each service
print_status "Configuring postiz-backend service..."
set_service_vars "postiz-backend" "${CORE_VARS[@]}" "${URL_VARS[@]}" "${STORAGE_VARS[@]}"

print_status "Configuring postiz-frontend service..."
set_service_vars "postiz-frontend" "${CORE_VARS[@]}" "${URL_VARS[@]}"

print_status "Configuring postiz-workers service..."
set_service_vars "postiz-workers" "${CORE_VARS[@]}" "${STORAGE_VARS[@]}"

print_status "Configuring postiz-cron service..."
set_service_vars "postiz-cron" "${CORE_VARS[@]}"

print_status "Configuring postiz-command service..."
set_service_vars "postiz-command" "${CORE_VARS[@]}"

print_status "Configuring postiz-extension service..."
set_service_vars "postiz-extension" "${CORE_VARS[@]}"

# Deploy all services
print_status "Deploying all services..."
railway up --detach || print_error "Deployment failed"

print_success "Railway setup completed!"
echo ""
echo "=================================================="
echo "    Important Information"
echo "=================================================="
echo "JWT Secret: ${JWT_SECRET}"
echo ""
echo "Next Steps:"
echo "1. Wait for deployment to complete (~5-10 minutes)"
echo "2. Check Railway dashboard for service URLs"
echo "3. Update FRONTEND_URL and NEXT_PUBLIC_BACKEND_URL with actual URLs"
echo "4. Visit your frontend URL to access Postiz"
echo ""
echo "Optional: Add these integrations later:"
echo "- RESEND_API_KEY for email notifications"
echo "- OPENAI_API_KEY for AI features"
echo "- Social media API keys (Twitter, LinkedIn, etc.)"
echo "=================================================="

print_warning "Save the JWT secret securely!"