# Changelog

All notable changes to the `project` plugin are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

The `Status` section of [the plugin README](plugins/project/README.md) carries the *reasoning*
behind each change — why the tool needed it. This file carries what changed. Releases before 2.7.0
are summarised from that section and from git history.

## [Unreleased]

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

[Unreleased]: https://github.com/voyvodka/claude-project-flow/compare/v2.7.0...HEAD
[2.7.0]: https://github.com/voyvodka/claude-project-flow/releases/tag/v2.7.0
[2.6.0]: https://github.com/voyvodka/claude-project-flow/compare/v2.5.0...v2.6.0
[2.5.0]: https://github.com/voyvodka/claude-project-flow/compare/v2.4.0...v2.5.0
[2.4.0]: https://github.com/voyvodka/claude-project-flow/releases/tag/v2.4.0
