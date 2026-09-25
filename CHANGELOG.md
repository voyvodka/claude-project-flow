# Changelog

All notable changes to the `project-flow` plugin are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

From 2.7.0 onward this file is the one record of what changed and why. The `Status` section of
[the plugin README](plugins/project-flow/README.md) is frozen pre-2.7.0 history, kept for the
reasoning behind those releases; the entries below for them are summarised from it and from git
history.

## [Unreleased]

## [3.0.3] - 2026-09-25

### Added

- CI checks the changelog's link footer: `[Unreleased]` compares from the newest version, every
  tagged version has a ref, and no ref points at a tag that does not exist. The newest version may
  be untagged, because a release PR adds its heading before the tag. The checkout now fetches full
  history so the check can see the tags.
- The CI routing check also resolves every `profile/*.md` path a phase reference or `SKILL.md`
  names, not only the templates.

### Fixed

- **The cache check could not fire.** `self-improvement.md` told the reader to stop if
  `${CLAUDE_PLUGIN_ROOT}` pointed into `plugins/cache/`, but Claude Code substitutes that variable
  only into skill, command and agent bodies as they load. It is not in the Bash environment and not
  substituted into a reference file read later, so the reader saw the literal string. The check
  now lives in `SKILL.md`, where the path is substituted, with the skill's base directory as the
  fallback, and `self-improvement.md` points at it.
- **The decision record had six lines in the template and "five fields" in the reference.**
  `templates/02-decisions.md` carries a `Kaynak` line that `phase-3-decide.md` never mentioned, and
  told the reader to leave `Bağlı olduğu varsayım` blank where the reference required all five.
  Phase 3 now says five required fields plus an optional Source, gives the English label for it,
  and says an entry resting on no assumption writes "—".
- **Phase 1 counted six blocking items in a table of seven.** Item 6b, existing skill, is blocking,
  and a reader counting to six could close the gate without it. The count now says seven, 1–6
  and 6b.
- **Turkish template literals leaked into English projects.** Only the decision labels had a
  translation rule; `Ek bilgiler`, `yok / uygulanmaz`, `Belge düzeni` and the rest did not, and
  the English-only `CLAUDE.md` template quoted the Turkish `Elenenler` label. `SKILL.md` now carries
  one rule — headings and literals follow the document's language, the section set is what is
  fixed — and the `CLAUDE.md` template names the line by what it holds.
- `phase-4-scaffold.md` and the `AGENTS.md` template still described `CLAUDE.md` as holding a map
  of `docs/`, which 2.6.0 moved into `docs/README.md`. Both now say pointer, and Phase 4's table
  lists `docs/README.md` among the files it produces.
- The profile's safety rails called themselves absolute while `profile/README.md` called
  everything in the profile a default, and Phase 5 said "run it" against a rail forbidding tests
  unasked. The rails are now the named exception, and Phase 5 asks before running tests when they
  forbid it, reporting the increment as unverified if the answer is no.
- `00-state.md` had nowhere for the records the phases tell it to keep — dispatched research
  branches, the compact layout, a merge-or-replace choice, tooling built on request — while
  `SKILL.md` forbids new headings. The template gains a `Belge düzeni` line and says where the rest
  go.
- `phase-0-detect.md` said never to skip Phase 0, while `SKILL.md` routes past it whenever a state
  file exists. Both now say the same thing.
- Three statements disagreed about where the reasoning for each version lives. The changelog intro
  and the root README now match the plugin README: `CHANGELOG.md` from 2.7.0, frozen `Status`
  before it.
- `3.0.1` still recorded the frozen `Status` section twice, under `Fixed` and `Changed`, and `2.8.0`
  still had a blank line splitting its `Fixed` list — both after `3.0.2` said they were merged.
- The changelog footer pointed `[Unreleased]` at `v3.0.1`, had no `[3.0.2]` ref, and linked
  `v2.4.0`, `v2.5.0` and `v2.6.0`, tags that were never created. Those three headings are now
  plain text.
- Leftover `project` names in the plugin README title and the changelog intro; "the last five
  phases" in Phase 4, where four come before it; a dangling section reference and a miscounted
  list in `dotnet-api-contracts.md`; a CI comment that described `set -eo pipefail` where the
  runner uses `bash -e`.

### Security

- **`/project` pre-approved unscoped `Bash`, `Write`, `Edit` and `WebFetch`.** `allowed-tools`
  grants permission without a prompt for the turn it runs in, so `git commit`, `git init` or a
  database command could run unasked — against the skill's own rule that git runs only on request.
  The command now pre-approves only reads and read-only git (`git status`, `git log`, `git diff`,
  `ls`); writes and fetches go through the normal permission flow.

## [3.0.2] - 2026-09-08

### Fixed

- **The research phase told the subagent to use Context7 and gave it no way to proceed without it.**
  `phase-2-research.md` said "use Context7 (resolve-library-id, then query-docs) … Do not answer
  from memory", but this plugin declares no dependency on Context7 and nothing installs it. On a
  machine without it the branch had an instruction it could not follow and no stated alternative,
  against a rule that forbids answering from memory — so the only exit was the one the rule
  forbids. `profile/code-style.md` already said "Context7 **or the registry**", so the two files
  disagreed about whether the tool was required. The rule now leads with what is actually
  non-negotiable (never answer from memory), prefers a docs tool where the session has one, and
  names the registry commands to fall back to. The sibling `web-launcher` skill reached the same
  shape from the same problem.
- **`self-improvement.md` sent the observation log into a directory the next update deletes.**
  "Where the edit has to land" tells the reader to stop when `${CLAUDE_PLUGIN_ROOT}` is inside a
  `plugins/cache/` path, but the "Logging" section below it said, without qualification, to append
  to `feedback/observations.md` — a file in that same cache. A reader arriving straight at Logging
  appended an observation that a marketplace update then wiped, silently, having counted it as
  recorded. The constraint is now restated where the writing actually happens.
- **Two release blocks in this changelog held the same fixes twice.** `3.0.1` and `2.8.0` each
  carried two `### Fixed` headings, because separate pull requests each appended to `[Unreleased]`
  and the release stamped both without merging them. `3.0.1`'s second block restated the first in
  different words; `2.8.0`'s split thirteen genuine entries across two lists with a `### Changed`
  between them. Merged, with every unique entry kept.

### Added

- CI checks the changelog's structure: no section heading twice inside one version block, only
  Keep a Changelog section names, an `[Unreleased]` section that the next change can land in, and
  one dated heading per version. The duplication above was found by reading the file weeks later,
  and it is mechanically detectable — so it is checked rather than trusted, which is the standard
  this plugin applies to every project it touches.

## [3.0.1] - 2026-08-28

### Fixed

- **`phase-3-decide.md` told the reader the decision record has four fields**, while a paragraph
  further down — untouched by that edit — describes `Kabul edilen bedel` / accepted cost as
  mandatory, down to what to write when there is none. An agent following the explicit "four fields
  are what is fixed" instruction would drop it. The reference now describes all five, in both the
  Turkish block and the English label mapping, and says to write "—" when a decision genuinely
  costs nothing rather than dropping the line.
- The CI routing check aborted opaquely on the condition it exists to report: `grep` exits 1 when it
  matches nothing, and under `set -eo pipefail` that killed the step before the `::error::`
  annotation was printed. It now annotates and fails deliberately.

### Changed

- **The README's `Status` section is frozen as pre-2.7.0 history.** It duplicated the changelog and
  went stale twice in one day — backfilled at 2.7.0, then three more releases shipped past it —
  which is the failure this plugin warns about everywhere else. The cause was keeping the same
  history in two files, so the cause is gone: the authoritative record from 2.7.0 onward is
  `CHANGELOG.md`, and the older entries stay because their reasoning predates the changelog and is
  still worth reading.

## [3.0.0] - 2026-08-28

### Changed

- **The plugin is renamed from `project` to `project-flow`.** BREAKING for the install key: it is
  now `/plugin install project-flow@voyvodka`, and `enabledPlugins` entries move accordingly. The
  catalog carries a `renames` entry so Claude Code v2.1.193+ rewrites existing settings
  automatically and reports the change; because the source is remote, expect one
  `plugin-cache-miss` and a single `/plugin install` to pick it up under the new name.

  `project` was a bare dictionary word standing in for a plugin about phased project delivery. It
  collides easily — `cyberswat/claude-plugin-projects` already occupies the same space on GitHub —
  and a generic install key is the one identifier a user cannot disambiguate at install time. The
  skill one directory down has been called `project-flow` since the first release; the plugin now
  matches it.

  The repository name (`claude-project-flow`) is unchanged, and **the `/project` command is
  unchanged** — it still starts, resumes and advances a project exactly as before. What moved is the
  install key and the skill's namespaced id, which is now `project-flow:project-flow`.

- `plugins/project/` is now `plugins/project-flow/`, so the plugin directory matches the plugin name.

### Fixed

- **The `.gitignore` rule protecting `profile/local/` was pinned to `plugins/project/...`** and
  stopped matching the moment that directory was renamed. An ignore rule a rename can silently
  switch off is not an ignore rule; it is now `**/profile/local/`. CI also asserts that nothing
  under `profile/local/` is tracked, so the protection is checked rather than assumed.

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

[Unreleased]: https://github.com/voyvodka/claude-project-flow/compare/v3.0.3...HEAD
[3.0.3]: https://github.com/voyvodka/claude-project-flow/compare/v3.0.2...v3.0.3
[3.0.2]: https://github.com/voyvodka/claude-project-flow/compare/v3.0.1...v3.0.2
[3.0.1]: https://github.com/voyvodka/claude-project-flow/compare/v3.0.0...v3.0.1
[3.0.0]: https://github.com/voyvodka/claude-project-flow/compare/v2.8.0...v3.0.0
[2.8.0]: https://github.com/voyvodka/claude-project-flow/compare/v2.7.0...v2.8.0
[2.7.0]: https://github.com/voyvodka/claude-project-flow/releases/tag/v2.7.0
