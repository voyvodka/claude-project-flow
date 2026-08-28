# Code Style

Cross-cutting rules. These hold in every language and every project — read this one always.

## Language

**Code, identifiers, comments and commit messages are English.** That one holds everywhere.

**Documentation defaults to Turkish** — like everything else under `profile/`, a default rather
than a rule, confirmed in Phase 1 against the project at hand. A project with non-Turkish-speaking
readers overrides it, and `SKILL.md` is the authority: documents follow the user's own language.

If a project already uses Turkish-without-diacritics identifiers, match it rather than
converting; consistency inside a file beats correctness across the repository.

## Comments

**Clean code first, comments second.** The preference is for as few as possible. A comment on
every line is noise, and noise is what stops the important comments from being read.

Comment a non-obvious *why* — a gotcha, a workaround, an invariant, a subtle edge case, or a short
navigation label. Never restate what the code plainly does. A menu item gated to Development and
Staging does not need a comment saying it is shown in Development and Staging. Prefer no comment
over a redundant one.

**Doc summaries are the exception, and they are worth it.** A shared or general-purpose function —
a repository method, a service method, a hook, a utility — carries a one-or-two-line summary
saying what it is for. Not a restatement of the body: an abstract. These are the functions called
from places that will never open the file, and the summary is what makes them usable without doing
so. A single-use private helper does not need one.

Per language:

| Language | Form |
|---|---|
| C# | `/// <summary>…</summary>` |
| TypeScript | JSDoc `/** … */`, or a short `//` for something small |
| Rust | `///` |
| Go | A sentence starting with the identifier's name, directly above it |
| Dart | `///` |
| Python | A one-line docstring |

**API controller actions are exempt.** Their route and OpenAPI metadata already describe them, and
a summary would only repeat it.

The rule applies to new and hand-written code. Copied legacy code is exempt until it is rewritten.

## Naming

| Language | Rule |
|---|---|
| C# | `PascalCase` for types, methods, properties; `camelCase` for parameters and locals; `_camelCase` for private fields |
| TypeScript | Components `PascalCase.tsx`; hooks `useXxx.ts`; services `<area>Service.ts`, colocated with the feature that uses them |

DTOs are clean `camelCase` `sealed record` types with `get; init;`. **Property names are never
renamed across the mapping boundary** — AutoMapper matches by name, and a rename turns a compile-
time contract into a silent runtime null.

## File extensions

**No `.js` or `.jsx` anywhere.** Every file is `.ts` or `.tsx`, configuration included
(`eslint.config.ts`, `vite.config.ts`). A JavaScript config file is the one place type errors
hide.

## Dependencies

**Latest stable, always** — pinned at install, no beta or release-candidate versions in a project
meant to ship. The default is to be current, not conservative.

The one thing that overrides it is tooling that has not caught up. TypeScript is the live example:
**TS 7 is out and is not in use yet only because lint support is not there.** That is a temporary
block with a named unblock condition, not a preference for an older version — when the tooling
lands, move.

Write pins down that way. A pin recorded as "held at 6.x" gets carried for years by people who do
not know why; a pin recorded as "held at 6.x until lint supports 7" gets released the moment it
can be.

### Never write a version number from memory

This is the rule that makes "latest stable" achievable rather than aspirational, and it is the one
that gets broken silently.

**Do not hand-write versions into a manifest.** Training data is stale by definition, and a
plausible-looking version number is indistinguishable from a correct one — the manifest installs,
the project builds, and the staleness is only noticed months later by someone reading it.

Instead:

- **Let the package manager resolve it.** `bun add <pkg>`, `pnpm add <pkg>`, `dotnet add package
  <pkg>` each write the current version into the manifest. Add dependencies with the tool, not with
  an editor.
- **A scaffold's pinned versions are as old as the scaffold.** Official generators are the right
  starting point, but what they emit was current when the template was published. After scaffolding,
  update — and check what actually landed rather than assuming.
- **A version stated in a document is a factual claim** and needs the same treatment as any other:
  verify it through Context7 or the registry, and say when it was checked. A research file asserting
  a major version without a date is a claim with an expiry nobody can see.

**No JavaScript.** TypeScript, everywhere, including configuration files.

## Package manager

**Bun is the preference.** Reach for it first.

It is a preference and not a rule: where another manager is measurably faster or more stable for a
particular project, take it — one of the current projects uses pnpm for exactly that reason, and
that is fine, not a compromise. The choice is made once per project on evidence.

Once made, it is fixed: **the `packageManager` field is authoritative and never switched or
mixed.** A repository with two lockfiles has two dependency graphs.

## The warning ledger

When a build, lint or analyzer warning appears — especially a deprecation — do three things:

1. Fix the call site.
2. Add **one line** to the project's `gotchas.md`.
3. Do not write it again.

Keep the ledger short. It is a working reference, not an archive; an entry nobody reads costs
more than the warning it describes. The mature version of this file separates **active rules**
(forward-looking, apply when writing new code) from **accepted risks** (deliberate trade-offs,
"know" rather than "fix") from **archive** (historical record only). When adding an entry, decide
which of the three it is.

## Documentation order

**When a decision or state changes, update the document first, then the code.** Not afterwards —
documentation written after the fact records what was built, not what was decided, and the two
diverge exactly where it matters.

**A changed decision is rewritten in place, as current truth.** Do not leave the old version
standing in a separate paragraph. Git holds the history; the file holds what is true now. Two
versions side by side means a reader cannot tell which one binds them, and they will follow the
more specific one — usually the stale one.

## Safety rails

These are absolute and hold in every project.

- **Never run EF migration or database update commands.** Not `dotnet ef migrations add`, not
  `database update`, `remove`, or `script`. Write the entity change and tell the user the command.
  Migration naming is sequential `vNNN` — find the next number from the migrations directory.
- **Never run git commands** unless the user explicitly asks. Commit and push only on request.
- **Never run tests** unless the user explicitly asks.
- **Commit messages are short:** a Conventional Commit type and a single-line summary. No body.
  No AI attribution lines, trailers, or "generated with" footers — anywhere, ever.
- **A shared development database is read-only.** Even when the connection has write permission,
  and even when testing a negative path: use input that is certain to fail before it reaches
  mutating code. If unsure, `SELECT` first and confirm the state.
