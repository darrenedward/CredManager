# JavaScript/TypeScript Style Guide

## Variable Declarations
- Use `const` for variables that won't be reassigned
- Use `let` for variables that will be reassigned
- Avoid `var`

## Functions
- Use arrow functions for concise expressions
- Use named functions for complex logic
- Prefer async/await over promises for readability

## Imports and Exports
- Use ES6 imports/exports
- Group imports: React, third-party, local
- Use absolute imports with `@/` alias
- Avoid wildcard imports

## TypeScript Specific
- Always use explicit type annotations for parameters and return types
- Define interfaces for objects and props
- Use generics for reusable types
- Avoid `any`; use `unknown` or specific types

## Async/Await
- Use async/await for asynchronous operations
- Handle errors with try-catch blocks
- Avoid mixing promises and async/await

## Error Handling
- Use try-catch for async operations
- Provide meaningful error messages
- Log errors appropriately

## React-Specific Practices
- Use functional components with hooks
- Define prop types with interfaces
- Use `useEffect` for side effects
- Avoid unnecessary re-renders

## Code Structure
- Keep functions small and focused
- Use early returns for clarity
- Follow DRY principle

## Examples

### Variable Declarations
```typescript
const userName = 'John';
let count = 0;
```

### Functions
```typescript
const calculateTotal = (items: Item[]): number => {
  return items.reduce((sum, item) => sum + item.price, 0);
};
```

### Async/Await
```typescript
const fetchUser = async (id: string): Promise<User> => {
  try {
    const response = await fetch(`/api/users/${id}`);
    return await response.json();
  } catch (error) {
    console.error('Failed to fetch user:', error);
    throw error;
  }
};
```

### Imports
```typescript
import React from 'react';
import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { calculateTotal } from '@/lib/utils';
```

### TypeScript Interface
```typescript
interface User {
  id: string;
  name: string;
  email: string;
}

const UserProfile: React.FC<{ user: User }> = ({ user }) => {
  return <div>{user.name}</div>;
};
```
