# Repository Layout

How the top level of a repository is arranged. Decided in Phase 3, recorded as a decision, and
built in the first increment — moving a directory tree later invalidates every path written into
the documentation.

## One of each surface — flat, named for what it is

```
project/
  CLAUDE.md · AGENTS.md
  docs/
  backend/
  frontend/
```

Add `mobile/` or `desktop/` on the same level when they exist. Supporting directories stay flat
and descriptive too: `deploy/`, `docs/`, whatever the project actually needs.

This is the default and it covers most projects. `backend/` and `frontend/` say what they are with
no indirection, and a newcomer finds the code without being told where it is.

**A single-surface project needs no wrapper at all.** A desktop application, a static site, a CLI
tool is just the project at the root — wrapping it in `app/` adds a level that carries no
information.

## Inside a surface, the ecosystem wins

`backend/` holds the .NET solution laid out the way .NET solutions are laid out. `mobile/` holds
the Expo project the way Expo expects it. A Tauri app keeps `src/` and `src-tauri/` side by side
because that is what the framework requires.

The top-level split is about **surfaces**. Below it, the ecosystem's own convention is not
negotiable — fighting it costs tooling support and gains nothing.

## Several of one kind — workspaces, but only when they share code

Two frontends, or two services, raise the question. The answer depends on one thing:

**Is there code shared between them?**

- **No shared code** → they are still separate directories. `admin-web/` and `public-web/` at the
  top level, named for what they are. Two applications that happen to live in one repository are
  not a monorepo, and giving them a workspace adds tooling that manages nothing.
- **Shared code** → `apps/<name>` plus `packages/<shared>`, using the package manager's native
  workspaces. Both bun and pnpm support this directly; no separate monorepo tool is needed until
  the build graph genuinely requires one.

The trigger is shared code, not app count. This matters because the workspace shape is easy to
adopt early "for later" and then costs a rename of every path when the shared package never
materialises.

### What counts as one surface

A codebase that produces several artefacts from one source is **one** surface. An Expo project
building a member app and a staff app from two build profiles is one `mobile/` directory, not two.
Splitting it doubles the store and maintenance load and buys nothing — that was a real finding
during research, not a stylistic call.

## Deciding

Pick the shape in Phase 3 alongside the stack, and record it in `02-decisions.md` — including
which trigger was used, so the next person knows what would justify changing it.

Build it in the first increment. A layout change after two increments touches every import, every
CI path, and every path written into `CLAUDE.md` and the docs.

When unsure, start flat. Going from `backend/` + `frontend/` to a workspace later is a mechanical
move once there is real shared code to justify it; going the other way means admitting the
structure was ceremony, which people tend not to do.
