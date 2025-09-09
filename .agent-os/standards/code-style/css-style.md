# CSS Style Guide

We use TailwindCSS 4.1.12 for all CSS styling in our Next.js/React projects.

### Multi-line CSS Classes in JSX

- Use a unique multi-line formatting style when writing Tailwind CSS classes in JSX, where the classes for each responsive size are written on their own dedicated line.
- The top-most line should be the smallest size (no responsive prefix). Each line below it should be the next responsive size up.
- Each line of CSS classes should be aligned vertically.
- Focus and hover classes should be on their own additional dedicated lines.
- We implement one additional responsive breakpoint size called 'xs' which represents 400px.
- If there are any custom CSS classes being used, those should be included at the start of the first line.
- All custom styles must be defined in `global.css` to maintain consistency.

**Example of multi-line Tailwind CSS classes in JSX:**

```jsx
<div className="custom-cta bg-gray-50 dark:bg-gray-900 p-4 rounded cursor-pointer w-full
                hover:bg-gray-100 dark:hover:bg-gray-800
                xs:p-6
                sm:p-8 sm:font-medium
                md:p-10 md:text-lg
                lg:p-12 lg:text-xl lg:font-semibold lg:w-3/5
                xl:p-14 xl:text-2xl
                2xl:p-16 2xl:text-3xl 2xl:font-bold 2xl:w-3/4">
  I'm a call-to-action!
</div>
```

### shadcn/ui Integration

- Use shadcn/ui components for consistent UI elements.
- Customize shadcn components via `global.css` or Tailwind config, not inline styles.
- Avoid overriding shadcn styles directly in components; use utility classes or extend in `global.css`.
- Use the shadcn MCP tool to explore available components and view example codes for implementation.

### Global CSS Best Practices

- All custom CSS should be centralized in `global.css`.
- Use Tailwind's `@apply` directive for reusable component styles.
- Avoid inline styles or component-scoped CSS modules.
- Ensure dark mode support with `dark:` prefixes.
- Test styles across breakpoints and themes.

### TailwindCSS Configuration

- Customize breakpoints in `tailwind.config.js` if needed.
- Use CSS variables for theme colors in `global.css`.
- Keep the config file minimal and focused on project-specific overrides.
