# Node.js Best Practices (Runterra)

Guidelines for backend development in the Runterra project.

## Core Patterns
- **Modularity:** Keep domain logic in `src/modules`. Avoid bloated controllers; delegate to services or repositories.
- **Async/Await:** Always use async/await. Handle errors using a global error-handling middleware or specific try/catch blocks where necessary.
- **Graceful Shutdown:** Refer to `server.ts`. Ensure DB connections and WebSocket servers are closed properly on SIGTERM/SIGINT.
- **Logging:** Use the shared `logger` (`src/shared/logger.ts`). Log request metadata, performance durations, and errors with context.

## Performance & Security
- **Rate Limiting:** Apply `apiLimiter` to all public API routes.
- **Body Size:** Keep `JSON_BODY_LIMIT` at 1mb to prevent DoS.
- **Statelessness:** The API should be stateless. Use Firebase tokens for every request.

## Project Structure
- `api/`: Express routers and middleware.
- `db/`: Migrations, seeds, and repositories.
- `modules/`: Entities, DTOs, and business logic.
- `shared/`: Utilities, constants, and logging.
