# Code Style Guide

## Context

Global code style rules for Agent OS projects.

## General Formatting

### Component and CSS Usage

- Use shadcn/ui and TailwindCSS for all UI components.
- All styling must use global utility classes from Tailwind (defined in `global.css` or equivalent).
- Do not use static or inline CSS in component files.
- Centralize any custom styles in `global.css` for maintainability and consistency.
- All shared UI elements (cards, buttons, etc.) should use global/shared components to ensure easy updates and consistent design.

### Indentation
- Use 2 spaces for indentation (never tabs)
- Maintain consistent indentation throughout files
- Align nested structures for readability

### Naming Conventions

- **Next.js / React / TypeScript:**
  - Variables & functions: `camelCase` (e.g., `userProfile`, `calculateTotal`)
  - Classes & React components: `PascalCase` (e.g., `UserProfile`, `PaymentProcessor`)
  - Constants: `UPPER_SNAKE_CASE` (e.g., `MAX_RETRY_COUNT`)
  - Filenames: `camelCase` or `PascalCase` for components, `kebab-case` for pages (project preference)

- **PostgreSQL:**
  - Table & column names: `lowercase_with_underscores` (e.g., `user_profile`, `created_at`)
  - Avoid quoted/case-sensitive identifiers for simplicity and compatibility

- **CSS / TailwindCSS:**
  - Class names: `kebab-case` (e.g., `bg-blue-500`, `flex-col`)
  - Utility classes: always lowercase

### String Formatting
- Use single quotes for strings: `'Hello World'`
- Use double quotes only when interpolation is needed
- Use template literals for multi-line strings or complex interpolation

### Code Comments
- Every function, method, class, and component must have a JSDoc-style comment explaining what it does, its parameters, return value, and any side effects.
- Add brief comments above non-obvious business logic.
- Document complex algorithms or calculations.
- Explain the "why" behind implementation choices.
- Never remove existing comments unless removing the associated code.
- Update comments when modifying code to maintain accuracy.
- Keep comments concise and relevant.

## TypeScript Specific

- Always use explicit type annotations for function parameters and return types.
- Define interfaces for object shapes and props.
- Use generics where appropriate for reusable components.
- Prefer `const` assertions for immutable data.
- Avoid `any` type; use `unknown` or specific types.

## React Specific

- Use functional components with hooks.
- Define props interfaces for components.
- Use `useState`, `useEffect`, etc., appropriately.
- Keep components small and focused on a single responsibility.
- Use `React.memo` for performance optimization if needed.

## Next.js Specific

- Use App Router for new projects.
- Structure pages in `app/` directory.
- Use server components where possible for performance.
- Handle data fetching with `fetch` or Prisma in server components.
- Use API routes in `app/api/` for backend logic.

## PostgreSQL Specific

- Use Prisma for all database interactions.
- Write migrations in lowercase with underscores.
- Use transactions for multi-step operations.
- Index frequently queried columns.

## Testing

- Use Jest and Testing Library for unit and integration tests.
- Write tests for all components and functions.
- Use descriptive test names.
- Mock external dependencies.

## File Structure

- Organize components in `components/` folder.
- Use `lib/` for utilities and helpers.
- Place pages in `app/` for Next.js.
- Keep styles in `global.css`.

## Imports

- Use absolute imports with `@/` alias.
- Group imports: React, third-party, local.
- Avoid wildcard imports.

## Error Handling

- Use try-catch for async operations.
- Provide user-friendly error messages.
- Log errors appropriately.

## Linting and Formatting

- Use ESLint with Next.js config.
- Use Prettier for code formatting.
- Run linters before commits.
