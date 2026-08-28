# Desktop

**Tauri** — a Rust shell around a web frontend. Cross-platform: macOS, Windows, Linux.

Reference: a shipped cross-platform desktop app. See "Reference implementations" in [`README.md`](README.md#reference-implementations).

## Shape

- **Shell:** Tauri 2, `src-tauri/` with its own `Cargo.toml` and a pinned `rust-toolchain.toml`.
- **Frontend:** React 19 + TypeScript + Vite + Tailwind — the same stack as the web projects, so
  [`react-frontend.md`](react-frontend.md) applies to everything above the shell.
- **Package manager:** pnpm, with a workspace file.

Rust here sits at the shell level — window management, system integration, native calls. It is not
deep systems work, and a project that would need it to be is a different decision.

## Why not the alternatives

- **Electron:** ships a browser per application. Tauri uses the platform webview instead, and the
  size and memory difference is the whole point.
- **.NET MAUI:** would keep everything in one ecosystem, but the tooling and community around it
  are narrower, and it gives up the shared frontend stack that makes Tauri cheap here.

Neither is barred. Both need an argument that beats the above.

## Contract-first

The pattern that makes a Rust/TypeScript boundary tractable: **define the contract before either
side is implemented.** A shared contracts directory holds the command names, payload shapes,
status codes and persisted-state shape; both sides are written against it.

Back it with a verification script that checks the Rust handlers against the TypeScript
definitions, and run it after touching either. Without that check the boundary drifts silently —
a renamed command fails at runtime, in the one place there is no type system spanning the gap.

## Feature modules

Each feature is a directory with the same internal shape:

| Subdirectory | Holds |
|---|---|
| `ui/` | React components |
| `state/` | State machine logic and hooks |
| `model/` | Domain types |
| `*Api.ts` | The `invoke()` bridge to Rust |

Rust commands group by concern in `src-tauri/src/commands/`, one file per area, rather than one
growing file of handlers.

State persistence goes through the store plugin behind a single facade — one module owns reads and
writes, and its shape is part of the contract.

## Release hygiene

The desktop project carries full open-source hygiene — `CHANGELOG.md`, `CONTRIBUTING.md`,
`CODE_OF_CONDUCT.md`, `SECURITY.md`, a licence. Match that for anything published; do not
manufacture it for something internal.
