# Changelog

All notable changes to the `project-flow` plugin are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

This file records what changed in each release; the reasoning behind a change is in its pull
request. For releases before 2.7.0 the reasoning is in the frozen `Status` section of
[the plugin README](plugins/project-flow/README.md), and the entries below for them are summarised
from it and from git history.

## [Unreleased]

## [3.2.1] - 2026-10-25

### Added

- `evals/stale-state`: fails when a session corrects a stale state file before the user approves it (#17).

## [3.2.0] - 2026-10-24

### Added

- `profile/macos-swift.md`: defaults and known traps for macOS-only native tools, indexed in the
  profile README (#14).
- `evals/`: six `claude plugin eval` cases covering detection, refusing early code, re-entry,
  phase announcement, skill triggering and staying out of unrelated requests (#15).

### Changed

- A project whose MVP or round has closed now routes to a re-entry step that checks the record and
  sends new work to an increment, a new round or maintenance (#14).
- `00-state.md` and `02-decisions.md` templates carry size limits; history moves to `archive/`,
  and a large decision record splits by topic (#14).
- A compact project that outgrows its two files is promoted to the five-file layout (#14).
- The tool never proposes waiving its own gates; a standing approval is recorded verbatim with its
  scope and expiry (#14).
- Routing announces the project's phase on every invocation, including when it opens with a
  concrete task (#14).
- The active phase reference is re-read after a context compaction (#14).
- `/project` pre-approves only the `Skill` tool (#14).
- Phase 5 lists increment steps in the reply when the task tools are unavailable (#14).
- Phase 4 notes that git worktrees lack local-only tooling and suggests a `.worktreeinclude` (#14).
- A state file that disagrees with the documents or the code is reported and corrected only on
  approval; a conflict with what the user said is still fixed at once (#15).
- A compact project's `Belge düzeni` line carries where decisions and the roadmap live (#15).
- Profile defaults updated: React Router 8, .NET application-part discovery, CSS-in-JS nonces,
  AutoMapper's licence, Next.js private folders and Astro hosting, each with source and date (#15).
- READMEs say the AI tooling can stay local and list `docs/README.md` in the produced tree (#15).

## [3.1.1] - 2026-10-14

### Changed

- **`/project` is a skill now, not a command file.** It moved from `commands/project.md` to
  `skills/project/SKILL.md` with `disable-model-invocation: true`; its name, arguments and tool
  grants are unchanged.
- READMEs lead with the one-step install, `/plugin install project-flow --marketplace
  voyvodka/claude-plugins` (Claude Code 2.1.275 or later), and keep the two-step form for older
  versions.

### Fixed

- **Phase 4 now says a rule file with broken frontmatter loads into every session**, not that it
  is dropped, and that path-scoped rules also load when a matching file is written or edited.

## [3.1.0] - 2026-09-25

### Added

- **Phase 4 wires verification into hooks instead of prose.** A settled fast check becomes a Stop
  hook in `.claude/settings.json`, the slow suite a git pre-push hook, and `CLAUDE.md` gains an
  optional Verification section.
- **`CLAUDE.md` has a budget of roughly 150 lines, and area rules go to `.claude/rules/`** with a
  `paths:` list, loading only for matching files. Phase 5 points new area rules there too.
- **The publication decision now covers the AI tooling.** Phase 3 asks whether `CLAUDE.md`,
  `AGENTS.md` and `.claude/` ship; if not, Phase 4 keeps them out through `.git/info/exclude`.

### Changed

- **Proposed subagents are read-only, on the cheapest model that does the job.** An advisory agent
  gets `Read`, `Grep`, `Glob` and `Bash` only when it must run a check.

## [3.0.3] - 2026-09-25

### Added

- CI checks the changelog's link footer and every `profile/*.md` path that `SKILL.md` or a phase
  reference names.

### Fixed

- **The plugin-cache check could not fire.** It moved from `self-improvement.md` into `SKILL.md`,
  where `${CLAUDE_PLUGIN_ROOT}` is substituted, with the skill's base directory as the fallback.
- **`phase-3-decide.md` matches `templates/02-decisions.md`:** five required fields plus an optional
  Source (`Kaynak`), with "—" for an entry resting on no assumption.
- **Phase 1 counts seven blocking items, 1–6 and 6b,** instead of six.
- **Turkish template literals no longer leak into English projects.** Headings and literals such as
  `Ek bilgiler` and `Elenenler` follow the document's language.
- `phase-4-scaffold.md` and the `AGENTS.md` template describe `CLAUDE.md` as a pointer to
  `docs/README.md`, which Phase 4 now lists among its outputs.
- The profile's safety rails are the named exception to its defaults, and Phase 5 asks before
  running tests when they forbid it.
- `00-state.md` gains a `Belge düzeni` line and says where the other records the phases keep belong.
- `phase-0-detect.md` and `SKILL.md` now agree on when Phase 0 is skipped.
- The changelog intro and root README agree on where release reasoning lives; leftover duplicate
  blocks in `3.0.1` and `2.8.0` and broken footer links are fixed.
- Small corrections in the plugin README title, Phase 4 and `dotnet-api-contracts.md`.

### Security

- **`/project` no longer pre-approves unscoped `Bash`, `Write`, `Edit` and `WebFetch`.** Its
  `allowed-tools` cover only reads and read-only git; writes and fetches prompt as usual.

## [3.0.2] - 2026-09-08

### Added

- CI checks the changelog's structure: Keep a Changelog section names, no section twice in a
  version, an `[Unreleased]` section, and one dated heading per version.

### Fixed

- **Phase 2 research no longer requires Context7.** `phase-2-research.md` prefers a docs tool when
  the session has one, falls back to registry commands, and still never answers from memory.
- **`self-improvement.md` no longer logs observations into the plugin cache** that the next update
  deletes; its Logging section carries the cache check.
- **Duplicate `### Fixed` blocks in `3.0.1` and `2.8.0` of this changelog are merged**, with every
  unique entry kept.

## [3.0.1] - 2026-08-28

### Changed

- **The README's `Status` section is frozen as pre-2.7.0 history.** From 2.7.0 onward
  `CHANGELOG.md` is the record of each release.

### Fixed

- **`phase-3-decide.md` describes all five decision-record fields**, including `Kabul edilen bedel`
  / accepted cost, written as "—" when a decision costs nothing.

## [3.0.0] - 2026-08-28

### Changed

- **The plugin is renamed from `project` to `project-flow`.** BREAKING: the install key is now
  `project-flow@voyvodka` and the skill id `project-flow:project-flow`; Claude Code v2.1.193+
  updates `enabledPlugins` automatically, and the `/project` command is unchanged.
- `plugins/project/` is now `plugins/project-flow/`, matching the plugin name.

### Fixed

- **The `.gitignore` rule protecting `profile/local/` is now `**/profile/local/`**, so it keeps
  matching after the plugin directory is renamed.

## [2.8.0] - 2026-08-28

### Fixed

- **Phase 2's Tech research carries conclusions, not transcription,** from
  `profile/local/infrastructure.md` into the committed `docs/research/tech.md`.
- **Phase 2 records launched research branches in `00-state.md`** and marks each done as it
  returns, so an interrupted fan-out no longer reads as finished.
- **`SKILL.md` names the two self-repair exceptions** next to its promise that the tool never edits
  itself without approval.
- **"No application code before Phase 5" now reads "no code that ships"**, with the Phase 3 spike
  as the one exception.
- **The compact "two documents" layout is defined:** a table names which file absorbs which, and
  the choice is recorded in `00-state.md`.
- **Phase 4 asks before writing over an existing `CLAUDE.md`, `AGENTS.md` or `docs/` tree**,
  offering merge, replace or write-alongside.
- The `Aktif faz` field carries a parenthesised status that tells a running phase from a finished
  one.
- `phase-0-detect.md`'s "Reconstructing state" heading says it runs after approval.
- **`phase-1-discover.md` stops after four question rounds;** whatever is still open becomes marked
  assumptions for Phase 2 to research.
- **Decision-record labels in `phase-3-decide.md` follow the document's language** instead of the
  hardcoded Turkish `Karar` / `Neden` / `Elenenler` / `Bağlı olduğu varsayım`.
- **`code-style.md` says to create `gotchas.md` on first use**, with its three-layer structure.
- Two `avoid.md` exclusions, Sentry and API versioning, are marked as unargued weak priors to raise
  in Phase 1.

## [2.7.0] - 2026-08-28

### Added

- `.github/workflows/validate.yml` runs `claude plugin validate --strict` and checks that the phase
  routing in `SKILL.md`, the references and the templates resolves.
- `$schema` in `plugin.json`.

### Removed

- A stray `version: 0.1.0` from the `SKILL.md` front matter.

### Fixed

- **`self-improvement.md` checks `${CLAUDE_PLUGIN_ROOT}` before applying an edit**, so an approved
  change no longer lands in a plugin cache the next update wipes.
- **The layout trees in `SKILL.md` and the plugin README list the project `README.md`** that Phase 5
  writes at MVP close.
- The README's `Status` section is backfilled through 2.6.0.
- `profile/code-style.md` gives Turkish documentation as a default, not a rule for every project;
  English for code stays absolute.

## [2.6.0] - 2026-08-12

### Changed

- The index of `docs/` moved from `CLAUDE.md` into `docs/README.md`, created in Phase 4 from the new
  `templates/docs-README.md`; `CLAUDE.md` keeps a pointer.

## [2.5.0] - 2026-08-12

### Changed

- For projects that already have code, Phase 1 asks the owner's bar for the product being fit to
  push before any outward goal.
- Phase 0 now asks what the source is silent on: whether its author considers it finished, and what
  quality bar they want.

## [2.4.0] - 2026-07-31

### Changed

- First public release. The developer profile split into committed templates carrying the
  questions and a gitignored `profile/local/` holding the answers, read in preference.

[Unreleased]: https://github.com/voyvodka/claude-project-flow/compare/v3.2.1...HEAD
[3.2.1]: https://github.com/voyvodka/claude-project-flow/compare/v3.2.0...v3.2.1
[3.2.0]: https://github.com/voyvodka/claude-project-flow/compare/v3.1.1...v3.2.0
[3.1.1]: https://github.com/voyvodka/claude-project-flow/compare/v3.1.0...v3.1.1
[3.1.0]: https://github.com/voyvodka/claude-project-flow/compare/v3.0.3...v3.1.0
[3.0.3]: https://github.com/voyvodka/claude-project-flow/compare/v3.0.2...v3.0.3
[3.0.2]: https://github.com/voyvodka/claude-project-flow/compare/v3.0.1...v3.0.2
[3.0.1]: https://github.com/voyvodka/claude-project-flow/compare/v3.0.0...v3.0.1
[3.0.0]: https://github.com/voyvodka/claude-project-flow/compare/v2.8.0...v3.0.0
[2.8.0]: https://github.com/voyvodka/claude-project-flow/compare/v2.7.0...v2.8.0
[2.7.0]: https://github.com/voyvodka/claude-project-flow/releases/tag/v2.7.0
