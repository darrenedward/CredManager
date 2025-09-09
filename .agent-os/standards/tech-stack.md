- Misc: clsx, zod, autoprefixer, postcss

## Containerization

- Docker Containers:
	- PostgreSQL (official image)
	- MinIO (official image)
	- Redis (official image)
- Container Registry: GitHub Container Registry (ghcr.io) for storing and distributing Docker images
# Tech Stack

## Context



Global tech stack defaults for Agent OS projects, overridable in project-specific `.agent-os/product/tech-stack.md`.

- App Framework: Next.js (15.5.2)
- Language: TypeScript (5.9.2)
- Primary Database: PostgreSQL (17.6)
- ORM: Prisma (6.15.0)
- JavaScript Framework: React (19.1.1)
- Build Tool: Next.js built-in
- Import Strategy: Node.js modules (npm)
- Package Manager: npm
- Node Version: 22 LTS
- CSS Framework: TailwindCSS (4.1.12)
- UI Components: shadcn/ui (latest), Radix UI, Lucide React icons
- Font Provider: Google Fonts
- Font Loading: Self-hosted for performance
- Icons: Lucide React components
- Application Hosting: Vercel (preferred), or self-hosted with Docker/Dokploy
- Hosting Region: Based on user base
- Database Hosting: Managed PostgreSQL (Vercel, Digital Ocean, or custom)
- Database Backups: Daily automated
- Asset Storage: Amazon S3, MinIO (optional)
- CDN: CloudFront
- Asset Access: Private with signed URLs
- CI/CD Platform: GitHub Actions
- CI/CD Trigger: Push to main/staging branches
- Tests: Jest (30.1.3), Testing Library (run before deployment)
- Rate Limiting: rate-limiter-flexible
- Production Environment: main branch
- Staging Environment: staging branch
- API Security: JWT, bcryptjs
- Environment Variables: dotenv
- Analytics/Charts: recharts
- Carousel: embla-carousel-react
- Misc: clsx, zod, autoprefixer, postcss

