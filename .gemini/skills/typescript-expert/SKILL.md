# TypeScript Expert (Runterra)

Ensuring type safety and consistency across the Runterra codebase.

## Standards
- **Strict Mode:** Always aim for strict type checking. Avoid `any` at all costs; use `unknown` if the type is truly unknown.
- **Zod for Validation:** Use `Zod` for runtime validation of API requests and external data. Sync Zod schemas with TypeScript interfaces.
- **Interfaces vs Types:** Use `interface` for public APIs and data models; use `type` for unions, intersections, and utility types.
- **Enums:** Prefer `native enums` for fixed sets of values (e.g., `UserStatus`, `ClubStatus`).

## Consistency
- **Naming:** use `PascalCase` for classes/interfaces/enums and `camelCase` for variables/functions.
- **Imports:** Use absolute paths where configured (e.g., `../modules/...`).
- **DTOs:** Always define explicit DTOs for request bodies and response payloads to prevent leaking internal database models.
