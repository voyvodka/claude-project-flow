# Changelog

All notable changes to the `project` plugin are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

The `Status` section of [the plugin README](plugins/project/README.md) carries the *reasoning*
behind each change — why the tool needed it. This file carries what changed. Releases before 2.7.0
are summarised from that section and from git history.

## [Unreleased]

## [2.8.0] - 2026-08-28

### Fixed

- **The research phase could carry private infrastructure detail into a committed file.** The Tech
  branch is told to paste `profile/infrastructure.md` into the subagent prompt. On any real machine
  that resolves to `profile/local/infrastructure.md`, which is gitignored precisely because it holds
  hostnames, provider and account names, port lists, domain portfolios and backup schedules. That
  branch writes into `docs/research/tech.md` — a file this tool tells the user to commit, in a
  different repository from the one the profile describes. Nothing said "conclusions, not
  transcription", so it depended entirely on the subagent's judgement. It is now an explicit rule,
  modelled on the wording the committed `infrastructure.md` already applies to itself.
- **Phase 2 could not tell an interrupted branch from a finished one.** Branches write straight to
  their final file, so a session that dies mid-fan-out leaves a file Phase 0 reads as complete.
  Launched branches are now recorded in `00-state.md` at dispatch and marked done as each returns —
  the rule Phase 5 already applies to increments.
- **`SKILL.md` stated an absolute that `self-improvement.md` contradicts.** "This tool never edits
  itself without the user's approval" sat next to two documented repair exceptions. The exceptions
  are now named where the promise is made.
- **"No application code before Phase 5" vs the Phase 3 spike.** Phase 3 explicitly writes and runs
  throwaway code. The directive now says "no code that ships" and names the spike as the one bounded
  exception, so the reader is not choosing which of two rules to break.
- **"Two documents instead of five" was never defined.** Phase 1 offers the compact shape; Phases 3-5
  then name `02-decisions.md` and `04-roadmap.md` directly, leaving a model that took the offer with
  two conflicting instructions. The compact layout is now a table naming exactly which file absorbs
  which, recorded in `00-state.md`.
- **Nothing asked before writing over an existing `CLAUDE.md`, `AGENTS.md` or `docs/` tree.**
  Phase 4 now stops, says what the existing file covers and where it disagrees, and offers
  merge / replace / write-alongside.
- The `Aktif faz` field enumerated phases 0-5 while Phase 5's closing step writes "MVP complete" into
  it, and nothing distinguished a phase that is running from one that finished. It now carries a
  parenthesised status.
- `phase-0-detect.md`'s "Reconstructing state" section did not say it runs after approval rather than
  before; the heading now does.

### Fixed

- **Phase 1's "round limit" was not a limit.** `SKILL.md` promises questioning is bounded and that
  leftover unknowns become marked assumptions, but `phase-1-discover.md` only said to *announce* a
  fourth round — with no ceiling and no conversion rule, so a user whose answers keep opening new
  ground could be questioned indefinitely, which is the exact failure the directive exists to
  prevent. Four rounds is now a hard ceiling; what is still open converts to marked assumptions and
  Phase 2 researches it.
- **The decision-record format hardcoded Turkish field labels.** `phase-3-decide.md` showed
  `Karar` / `Neden` / `Elenenler` / `Bağlı olduğu varsayım` as the literal block to fill in, while
  `SKILL.md` says product documents follow the user's own language — so an English-language project
  got Turkish headings inside otherwise English documents. The four *fields* are what is fixed; the
  labels follow the document.
- **`code-style.md` told the agent to append to a `gotchas.md` that nothing creates.** No phase
  scaffolds it and no template defines it, so the rule fired mid-implementation against a file that
  did not exist. It now says to create it on first use, with the three-layer structure already
  described a few lines below — deliberately not scaffolded up front, so a project that never hits a
  warning does not carry an empty ledger.
- Two `avoid.md` exclusions (Sentry, API versioning) carried no argument, while the file's own rule
  is that a candidate "has to beat the stated reason". With nothing stated there was nothing to
  beat. Both are now marked as unargued weak priors to be raised in Phase 1 rather than treated as
  settled.
- The rejected entry in `feedback/observations.md` was missing two fields its own logging template
  requires.

## [2.7.0] - 2026-08-28

### Fixed

- **The self-improvement loop could write into a directory that gets deleted.**
  `references/self-improvement.md` walks through proposing a change and then applying it to
  `SKILL.md` or a phase reference, and allows two classes of repair without asking — but never said
  where the edit lands. On a marketplace install that is a versioned plugin cache, wiped on the next
  update, silently, after the user approved the change and watched it be written.
  `profile/README.md` already documented this failure for `profile/local/`; it now covers the whole
  skill, with a check against `${CLAUDE_PLUGIN_ROOT}` before anything is applied.
- **Phase 5 wrote a file no layout tree listed.** A project `README.md` is written at MVP close from
  one of the two README templates, but neither `SKILL.md`'s target layout nor the plugin README's
  "What it produces" named it — while `phase-0-detect.md` treats a root `README.md` as a
  *pre-existing* signal. Both trees now list it and say when it appears.
- The `Status` section had stopped at 2.4.0 while `plugin.json` was at 2.6.0, so the reasoning for
  two releases existed only in commit bodies. Backfilled.
- `profile/code-style.md` stated "Documentation is Turkish" as an unconditional rule for every
  project, contradicting `profile/README.md` (everything under `profile/` is a default confirmed in
  Phase 1) and `SKILL.md` (documents follow the user's own language). Reworded as the default it is.
  The English-for-code half is unchanged and still absolute.

### Removed

- A stray `version: 0.1.0` from the `SKILL.md` front matter. Claude Code does not read it and it
  contradicted `plugin.json`.

### Added

- `.github/workflows/validate.yml` — `claude plugin validate --strict`, plus a check that the phase
  routing in `SKILL.md`, the reference files and the templates all resolve, in both directions. This
  skill's real failure mode is routing: a renamed reference breaks a phase at the moment that phase
  is needed, and manifest validation cannot see it.
- `.github/dependabot.yml` — monthly `github-actions` updates for the pinned action SHAs.
- `$schema` in `plugin.json`.

## [2.6.0] - 2026-08-12

### Changed

- The index of `docs/` moved from `CLAUDE.md` into `docs/README.md`, created in Phase 4 from a new
  `templates/docs-README.md`, so adding a document and listing it are the same motion. `CLAUDE.md`
  keeps the pointer and the entry point only.

## [2.5.0] - 2026-08-12

### Changed

- For projects that already have code, Phase 1's success-criterion question splits in two: the
  owner's bar for the product being fit to push comes before any outward goal.
- Phase 0 now asks what the source is silent on — whether its author considers it finished, and what
  quality bar they want.

## [2.4.0] - 2026-07-31

### Changed

- First public release. The developer profile split: committed files became templates carrying the
  questions, while the answers moved to a gitignored `profile/local/` read in preference to them.

[Unreleased]: https://github.com/voyvodka/claude-project-flow/compare/v2.8.0...HEAD
[2.8.0]: https://github.com/voyvodka/claude-project-flow/compare/v2.7.0...v2.8.0
[2.7.0]: https://github.com/voyvodka/claude-project-flow/releases/tag/v2.7.0
[2.6.0]: https://github.com/voyvodka/claude-project-flow/compare/v2.5.0...v2.6.0
[2.5.0]: https://github.com/voyvodka/claude-project-flow/compare/v2.4.0...v2.5.0
[2.4.0]: https://github.com/voyvodka/claude-project-flow/releases/tag/v2.4.0
