# Developer Profile

Standing answer to "what does this developer already know, and what would they reach for?"
Read at the start of Phase 1; the relevant stack file is handed to the Phase 2 tech branch so
that research starts from what is already known instead of from a blank page.

**Edit these files directly.** This directory is the one part of the plugin meant to be
personal, and it should be revised whenever the defaults stop being true.

Everything here is a **default, not a rule.** Phase 1 confirms it applies to the project at
hand; Phase 2 tests it against the project's actual needs. A default that survives that
scrutiny is a fast decision. A default that does not is exactly what research is for.

**Read only what the project needs.** A desktop app does not need the .NET API conventions.

> The stack files below are one developer's answers, kept as a worked example rather than as
> advice. Replace them. A profile that describes someone else is worse than an empty one,
> because it will be trusted.

## Personal overrides

`profile/local/` is **not committed**. Any file placed there is read *instead of* the file with
the same name one directory up.

```
profile/infrastructure.md          committed — the template
profile/local/infrastructure.md    ignored by git — the real one, read in preference
```

This is what keeps machine names, hostnames, open ports, e-mail addresses and workplace
repository paths out of a public repository while the plugin still runs against real answers
locally.

Two files are shipped as templates for exactly this reason and hold no real data until they are
filled in: [`infrastructure.md`](infrastructure.md) and
[`local-environment.md`](local-environment.md). Until one is filled in or overridden, treat its
subject as **genuinely open** and ask, rather than inventing a server or an identity.

## Index

| File | When to read it |
|---|---|
| [`code-style.md`](code-style.md) | **Always** — naming, comments, safety rails, doc order |
| [`dotnet-backend.md`](dotnet-backend.md) | Any business backend or API — architecture |
| [`dotnet-api-contracts.md`](dotnet-api-contracts.md) | The concrete shapes: envelope, list contract, base controller |
| [`react-frontend.md`](react-frontend.md) | Any web interface — stack and UI rules |
| [`react-structure.md`](react-structure.md) | Directory layout and keeping duplication out |
| [`nextjs.md`](nextjs.md) | **Only if Next.js was chosen** — not the default |
| [`go-service.md`](go-service.md) | Small services that do not justify a full solution |
| [`cli-go.md`](cli-go.md) | Command-line tools |
| [`mobile.md`](mobile.md) | Anything with a phone in it — **no default, read before assuming** |
| [`desktop-tauri.md`](desktop-tauri.md) | Desktop applications |
| [`static-site-astro.md`](static-site-astro.md) | Documentation and marketing sites |
| [`repo-layout.md`](repo-layout.md) | Phase 3, when deciding how the top level is arranged |
| [`local-environment.md`](local-environment.md) | **Always** — git identity, machine limits, local containers |
| [`infrastructure.md`](infrastructure.md) | Every project — hosting, CI, deployment target |
| [`project-docs.md`](project-docs.md) | Phase 4, before writing `CLAUDE.md` |
| [`avoid.md`](avoid.md) | Phase 2, before proposing candidates |

## How the code gets written

- **Development model:** solo, with heavy AI assistance. Claude Code writes most of the code.
- **What the human still does personally:** review, architecture, deployment, and the calls
  that need business judgement. A stack still has to be readable and debuggable by hand.
- **Consequence for stack selection:** weigh how well an agent can *verify its own work* in a
  candidate — types, a compiler, a fast test path, and whether the agent can run the thing and
  observe the result without a person in the loop.

## Reference implementations

The most reliable statement of these conventions is the code, not a list of package names. Read
the relevant repository before proposing a shape; each should carry its own `CLAUDE.md`.

Which repository demonstrates which shape is **machine-specific** — record it in
[`local-environment.md`](local-environment.md), or in the `local/` override of it, alongside a
note about which directories are workplace repositories that no conventions should be read out
of. Half-finished experiments are not a statement of preference.

## Defaults by project type

| Project type | Default | Detail |
|---|---|---|
| Web app (business) | .NET 10 layered backend + React 19 SPA | [`dotnet-backend.md`](dotnet-backend.md), [`react-frontend.md`](react-frontend.md) |
| API / backend service | .NET 10 layered solution | [`dotnet-backend.md`](dotnet-backend.md) |
| Lightweight web service | Go | [`go-service.md`](go-service.md) |
| Desktop | Tauri (Rust shell + React) | [`desktop-tauri.md`](desktop-tauri.md) |
| Docs / marketing site | Astro | [`static-site-astro.md`](static-site-astro.md) |
| Mobile | **No default — must be researched** | [`mobile.md`](mobile.md) |
| CLI | Go, standard library, zero dependencies | [`cli-go.md`](cli-go.md) |

## Constraints that always apply

Record the ones that are true everywhere, so no project has to rediscover them. Two that are
worth stating explicitly if they apply:

- **Jurisdiction.** Which data-protection regime covers the product's users, and where the
  hosting sits relative to it. This decides more designs than it looks like it should.
- **Cost discipline.** If a server is already paid for, it is a sunk cost and paid managed
  services need a real argument — see [`infrastructure.md`](infrastructure.md) for how to make
  that comparison honestly rather than by pricing the existing box at zero.

## Open questions

> Answer these and delete the entry. Until then, treat the topic as genuinely open rather than
> assuming a default.

- **Mobile.** See [`mobile.md`](mobile.md) — deliberately unresolved.

*(CLI was open until a real project settled it — see [`cli-go.md`](cli-go.md). This is the
intended pattern: a gap stays marked open until a project produces evidence, then the evidence
becomes the default.)*
