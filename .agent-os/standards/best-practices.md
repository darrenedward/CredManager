# Development Best Practices

## Context

Global development guidelines for Agent OS projects.

## Core Principles

### Keep It Simple
- Implement code in the fewest lines possible
- Avoid over-engineering solutions
- Choose straightforward approaches over clever ones

### Optimize for Readability
- Prioritize code clarity over micro-optimizations
- Write self-documenting code with clear variable names
- Add comments for "why" not "what"

### DRY (Don't Repeat Yourself)
- Extract repeated business logic to private methods
- Extract repeated UI markup to reusable components
- Create utility functions for common operations

### File Structure
- Keep files focused on a single responsibility
- Group related functionality together
- Use consistent naming conventions

#### Recommended Project Structure (Next.js/React/TypeScript)
```
project-root/
├── app/                          # Next.js App Router pages and API routes
│   ├── (auth)/                   # Route groups for auth pages
│   ├── api/                      # API routes (e.g., /api/users)
│   ├── dashboard/                # Page routes (e.g., /dashboard)
│   ├── globals.css               # Global Tailwind styles
│   ├── layout.tsx                # Root layout
│   └── page.tsx                  # Home page
├── components/                   # Reusable React components
│   ├── ui/                       # shadcn/ui components
│   ├── forms/                    # Form components
│   └── layout/                   # Layout components (e.g., Header, Footer)
├── lib/                          # Utility functions and configurations
│   ├── prisma/                   # Prisma client and utilities
│   ├── utils/                    # Helper functions
│   └── validations/              # Zod schemas
├── hooks/                        # Custom React hooks
├── types/                        # TypeScript type definitions
├── public/                       # Static assets (images, icons)
├── prisma/                       # Database schema and migrations
│   ├── schema.prisma
│   └── migrations/
├── tests/                        # Test files (Jest)
├── .env.local                    # Environment variables
├── tailwind.config.js            # Tailwind configuration
├── next.config.js                # Next.js configuration
├── package.json                  # Dependencies and scripts
└── README.md                     # Project documentation
```

## Dependencies

### Choose Libraries Wisely
When adding third-party dependencies:
- Select the most popular and actively maintained option
- Check the library's GitHub repository for:
  - Recent commits (within last 6 months)
  - Active issue resolution
  - Number of stars/downloads
  - Clear documentation
- Evaluate TypeScript support, bundle size (via Bundlephobia), and Next.js compatibility
- Prefer libraries that align with our tech stack (e.g., React ecosystem, Prisma-compatible)

## React/Next.js Best Practices

- Use functional components with hooks over class components
- Prefer server components in Next.js for better performance
- Handle data fetching in server components or with `useEffect` in client components
- Use `React.memo` sparingly for performance-critical components
- Keep components small and focused on one responsibility

## TypeScript Best Practices

- Enable strict mode in `tsconfig.json`
- Avoid `any` type; use `unknown` or specific types
- Define interfaces for props and data structures
- Use utility types (e.g., `Partial`, `Pick`) for reusability
- Leverage generics for flexible, type-safe functions

## Security Best Practices

- Validate inputs with Zod schemas
- Use environment variables for sensitive data (never hardcode secrets)
- Implement authentication with NextAuth.js
- Sanitize user inputs to prevent XSS
- Use HTTPS and secure headers in production
- Always rate limit API endpoints to prevent abuse
- Ensure all API endpoints are secure with proper authentication and authorization

## Development Workflow Best Practices

- Never use mock data; always create database migrations and seed with live data
- Always put the port number for the project in the .env file
- Use netstat or lsof to kill processes on specific ports when needed: `lsof -ti :${port} | xargs kill -9`
- Always run TypeScript tests after writing code to ensure no TypeScript errors
- Run `npm run build` to verify builds are clean
- Never leave code incomplete; always finish implementations and never leave "to be implemented" or "coming soon" placeholders
- Always use git for version control: add, commit, and use branches for feature development
- Setup package.json to use concurrent for development: run `npm run dev` from the root of the project

## Performance Best Practices

- Optimize images with Next.js `Image` component
- Use lazy loading for components and routes
- Minimize bundle size by tree-shaking unused code
- Cache database queries with Prisma
- Monitor performance with tools like Vercel Analytics

## Testing Best Practices

- Write unit tests for utilities and hooks
- Use integration tests for API routes and components
- Aim for high test coverage (>80%)
- Use Jest snapshots for UI components
- Test error scenarios and edge cases

## Error Handling Best Practices

- Use try-catch blocks for async operations
- Provide user-friendly error messages
- Log errors to a service like Sentry
- Implement fallback UI for failed states
- Avoid exposing sensitive error details to users

## Code Reviews and Collaboration

- Require pull request reviews for all changes
- Use descriptive commit messages
- Follow the code style guide for consistency
- Pair program for complex features
- Document breaking changes in PR descriptions
