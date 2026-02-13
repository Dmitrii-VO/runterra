# Next.js Best Practices (Runterra Admin)

Guidelines for the Runterra Admin panel built with Next.js.

## Architecture
- **App Router:** Use the Next.js App Router (`src/app`).
- **Server Components:** Leverage React Server Components for data fetching where possible.
- **Client Components:** Use `'use client'` sparingly for interactive elements.

## API Integration
- **Contracts:** Match backend DTOs. Ensure error handling follows ADR 0002.
- **Auth:** Pass Firebase tokens in headers. Handle expiration and redirects to login.

## UI/UX
- **Consistency:** Follow the Material Design principles as specified in the project goals.
- **Loading States:** Provide clear loading indicators (skeletons) during data fetch.
- **Forms:** Use robust form handling (e.g., React Hook Form) with Zod validation.
