# Project: Postiz - Social Media Management Platform

## Quick Start Commands
```bash
# Prerequisites check
node --version  # Must be 20.17.0
pnpm --version  # Must be 10.6.1

# Initial setup (run once)
cp .env.example .env
pnpm install
pnpm run dev:docker
pnpm run prisma-generate
pnpm run prisma-db-push

# Development
pnpm run dev           # Start all services
pnpm run dev:backend   # Backend only (port 3000)
pnpm run dev:frontend  # Frontend only (port 4200)
pnpm run dev:workers   # Workers only
pnpm run dev:cron      # Cron only

# Testing & Quality
pnpm test              # Run tests
pnpm run lint          # Lint code
pnpm run type-check    # Type checking
pnpm run build         # Build production

# Database
pnpm run prisma-generate  # Generate Prisma client
pnpm run prisma-db-push   # Push schema changes
pnpm run prisma-reset     # Reset database
```

## Project Architecture

### Monorepo Structure
- **Package Manager**: pnpm workspaces
- **Build System**: NX
- **Node Version**: 20.17.0 (managed via Volta)

### Core Applications
1. **Frontend** (`apps/frontend/`)
   - Next.js 14.x with React 18.3.1
   - TailwindCSS + Mantine UI
   - Port: 4200

2. **Backend** (`apps/backend/`)
   - NestJS 10.x API
   - Prisma ORM with PostgreSQL
   - Port: 3000

3. **Workers** (`apps/workers/`)
   - BullMQ job processors
   - Handles social media posting

4. **Cron** (`apps/cron/`)
   - Scheduled tasks
   - Token refresh, trending checks

### Shared Libraries
- `libraries/helpers/` - Utility functions
- `libraries/nestjs-libraries/` - Shared NestJS modules & Prisma schema
- `libraries/react-shared-libraries/` - Shared React components

## Environment Configuration

### Required Variables
```env
# Database
DATABASE_URL="postgresql://postiz-user:postiz-password@localhost:5432/postiz-db-local"
REDIS_URL="redis://localhost:6379"

# Security
JWT_SECRET="[generate-long-random-string]"

# Application URLs
FRONTEND_URL="http://localhost:4200"
NEXT_PUBLIC_BACKEND_URL="http://localhost:3000"
BACKEND_INTERNAL_URL="http://localhost:3000"

# Storage
STORAGE_PROVIDER="local"
```

### Optional but Important
- **Email**: `RESEND_API_KEY` - User activation emails
- **AI**: `OPENAI_API_KEY` - AI content generation
- **Payments**: `STRIPE_SECRET_KEY`, `STRIPE_PUBLISHABLE_KEY`

## Code Style Guidelines

### TypeScript Standards
- Use TypeScript for all new files
- Strict mode enabled
- No `any` types without justification
- Prefer interfaces over types for object shapes

### React/Next.js Patterns
- Functional components with hooks
- Server components by default (Next.js 14)
- Client components only when needed
- Custom hooks in `hooks/` directory

### NestJS Patterns
- Modular architecture
- Dependency injection
- DTOs for request/response validation
- Guards for authentication/authorization

### Testing Standards
- Unit tests for utilities and services
- Integration tests for API endpoints
- E2E tests for critical user flows
- Minimum 70% code coverage

## Development Workflow

### Before Starting Work
1. Pull latest changes: `git pull origin main`
2. Install dependencies: `pnpm install`
3. Start Docker services: `pnpm run dev:docker`
4. Check database migrations: `pnpm run prisma-generate`

### During Development
1. Use Plan Mode (`/plan`) for complex features
2. Run linting before commits: `pnpm run lint`
3. Test affected areas: `pnpm test -- --watch`
4. Keep Docker services running

### Before Committing
1. Run full test suite: `pnpm test`
2. Check types: `pnpm run type-check`
3. Lint code: `pnpm run lint`
4. Build verification: `pnpm run build`

## Social Platform Integrations

### Supported Platforms
- X (Twitter)
- LinkedIn
- Facebook & Instagram
- YouTube
- TikTok
- Reddit
- Discord & Slack
- Mastodon & Bluesky
- Pinterest
- Dribbble
- Threads

### Adding New Platform
1. Create provider in `libraries/nestjs-libraries/src/integrations/social/`
2. Add OAuth configuration
3. Implement posting interface
4. Add to frontend UI
5. Test with real account

## Database Schema

### Key Models
- **Organization**: Multi-tenant support
- **User**: Authentication & profiles
- **Post**: Content scheduling
- **Media**: File attachments
- **Integration**: Social accounts
- **Subscription**: Payment plans

### Migrations
```bash
# Create migration
pnpm run prisma migrate dev --name [migration-name]

# Apply migrations
pnpm run prisma migrate deploy

# Reset database (dev only)
pnpm run prisma migrate reset
```

## Troubleshooting

### Common Issues

#### Port Already in Use
```bash
# Kill process on port
lsof -ti:3000 | xargs kill -9  # Backend
lsof -ti:4200 | xargs kill -9  # Frontend
```

#### Database Connection Failed
```bash
# Check PostgreSQL is running
docker ps | grep postgres

# Restart Docker services
docker-compose -f docker-compose.dev.yaml down
pnpm run dev:docker
```

#### Redis Connection Failed
```bash
# Check Redis is running
docker ps | grep redis

# Clear Redis cache
redis-cli FLUSHALL
```

#### Build Failures
```bash
# Clean and rebuild
rm -rf node_modules
rm -rf apps/*/dist
pnpm install --force
pnpm run build
```

## Performance Optimization

### Frontend
- Image optimization with Next.js Image
- Code splitting and lazy loading
- Server-side rendering for SEO
- Static generation where possible

### Backend
- Database query optimization
- Redis caching strategies
- Queue processing optimization
- Rate limiting implementation

## Security Best Practices

### Authentication
- JWT with refresh tokens
- Bcrypt for password hashing
- Rate limiting on auth endpoints
- Session management

### API Security
- CORS configuration
- Input validation with DTOs
- SQL injection prevention (Prisma)
- XSS protection

### Environment Variables
- Never commit `.env` files
- Use different keys for dev/prod
- Rotate secrets regularly
- Minimal permissions principle

## Deployment

### Docker Production
```bash
# Build image
./var/docker/docker-build.sh

# Run container
./var/docker/docker-create.sh
```

### PM2 Process Manager
```bash
# Start all services
pnpm run pm2

# Monitor processes
pm2 monit

# View logs
pm2 logs
```

## Team Collaboration

### Git Workflow
1. Create feature branch: `git checkout -b feature/[name]`
2. Make changes and commit
3. Push branch: `git push origin feature/[name]`
4. Create pull request
5. Code review and merge

### Commit Convention
```
type(scope): description

feat: New feature
fix: Bug fix
docs: Documentation
style: Formatting
refactor: Code restructuring
test: Tests
chore: Maintenance
```

## MCP Configuration
- **context7**: Real-time documentation
- **filesystem**: Enhanced file operations
- **playwright**: E2E testing
- **GitHub**: Repository management
- **Brave Search**: Research capabilities

## Quality Gates
- Linting must pass
- Type checking must pass
- Tests must pass (70% coverage)
- Build must succeed
- Security audit must pass

## Emergency Procedures

### Rollback Deployment
```bash
# Revert to previous version
git revert HEAD
pnpm run build
pnpm run pm2:restart
```

### Database Recovery
```bash
# Backup current state
pg_dump $DATABASE_URL > backup.sql

# Restore from backup
psql $DATABASE_URL < backup.sql
```

### Clear All Caches
```bash
# Redis cache
redis-cli FLUSHALL

# Node modules
rm -rf node_modules
pnpm install

# Build cache
rm -rf .next
rm -rf dist
```

## Resources
- [Postiz Documentation](https://docs.postiz.com)
- [GitHub Repository](https://github.com/gitroomhq/postiz-app)
- [Discord Community](https://discord.gg/postiz)
- [YouTube Channel](https://youtube.com/@postizofficial)