# HTML/JSX Style Guide

## Structure Rules
- Use 2 spaces for indentation
- Place nested elements on new lines with proper indentation
- Content between tags should be on its own line when multi-line
- Use JSX syntax for React components

## Attribute Formatting
- Place each JSX attribute on its own line
- Align attributes vertically
- Keep the closing `>` on the same line as the last attribute
- Use `className` instead of `class`

## Semantic HTML
- Use semantic elements like `<header>`, `<nav>`, `<main>`, `<section>`, `<article>`, `<aside>`, `<footer>`
- Ensure proper heading hierarchy (h1-h6)
- Use `<button>` for interactive elements, not `<div>` with click handlers

## Accessibility
- Include `alt` text for images
- Use ARIA attributes when needed (e.g., `aria-label`, `role`)
- Ensure keyboard navigation support
- Test with screen readers

## React-Specific Practices
- Use `key` prop for list items
- Prefer React Fragments (`<>`) over unnecessary divs
- Use descriptive component names
- Avoid inline event handlers; use functions

## Example JSX Structure

```jsx
<div className="container">
  <header className="flex flex-col space-y-2
                     md:flex-row md:space-y-0 md:space-x-4">
    <h1 className="text-primary dark:text-primary-300">
      Page Title
    </h1>
    <nav className="flex flex-col space-y-2
                    md:flex-row md:space-y-0 md:space-x-4">
      <Link href="/"
            className="btn-ghost">
        Home
      </Link>
      <Link href="/about"
            className="btn-ghost">
        About
      </Link>
    </nav>
  </header>
</div>
```

## shadcn/ui Integration
- Use shadcn components for buttons, forms, etc.
- Ensure components are accessible out of the box
- Customize via props or Tailwind classes
