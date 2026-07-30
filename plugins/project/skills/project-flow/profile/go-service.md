# Lightweight Go Service

For web services small enough that a layered .NET solution would be more apparatus than the work
justifies. A personal site, a small API, a single-purpose endpoint.

Reference: a Go backend behind a React frontend, deliberately small. See "Reference implementations" in [`README.md`](README.md#reference-implementations).

## When to reach for it

The test is whether the project would spend more time carrying the structure than using it. A
layered solution earns its cost when there are real domain rules, several client surfaces, or a
long maintenance horizon. Below that, Go gives a single small binary with no framework to keep
current.

Not a default for anything with real business logic — that is [`dotnet-backend.md`](dotnet-backend.md).

## Shape

- Standard library first — the dependency argument is made in full in [`cli-go.md`](cli-go.md) and
  applies here unchanged.
- Single module, flat structure. Do not import the layered .NET shape into a project chosen
  precisely to avoid it.
- **SQLite is the default store at this size** — the portfolio uses it. A file on disk needs no
  container, no connection pool and no backup story beyond copying it, which is most of the reason
  to be at this size in the first place. Reach for PostgreSQL when concurrency, a second consumer,
  or real relational load arrives.
- Frontend stays React + Vite + TypeScript, so [`react-frontend.md`](react-frontend.md) still
  applies above the API.

## Deployment

Same as everything else — a container, CI, the existing host. See
[`infrastructure.md`](infrastructure.md). A single static Go binary makes for a very small image,
which is part of the appeal at this size.
