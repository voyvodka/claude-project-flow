# Project Documentation

Read this in Phase 4, before writing a project's `CLAUDE.md`.

New projects here already carry a documentation directory — `docs/` or `dev-docs/` — and it is a
habit worth matching rather than competing with. This tool should feel like the next entry in an
existing practice, not a second parallel system.

Reference: the mature example is a business web app's `dev-docs`. See "Reference implementations" in [`README.md`](README.md#reference-implementations).

## The established shape

A `CLAUDE.md` at the repository root, pointing into a documentation directory that holds:

| File | Holds |
|---|---|
| `README.md` | Status plus an index of everything else — read first |
| `decisions.md` | Architectural decisions, **numbered and cited by id** (C31, C13, …) |
| `conventions.md` | How code in this repository is written |
| `gotchas.md` | Traps specific to this project |
| `structure.md` | What lives where |
| `open-questions.md` | Unresolved items |
| `session-handoff.md` | Where work stopped and what comes next |
| `research/`, `future/` | Evidence, and ideas parked for later |

## Mapping

This tool's layout is the same practice under different names. Match the existing directory when
one is present; introduce this tool's names only in an empty folder.

| This tool | Established equivalent |
|---|---|
| `docs/product/00-state.md` | `session-handoff.md` + `open-questions.md` |
| `docs/product/02-decisions.md` | `decisions.md` |
| `docs/research/` | `research/` |
| `docs/product/03-mvp.md`, `04-roadmap.md` | no direct equivalent — add them |
| `CLAUDE.md` rules section | `conventions.md` + `gotchas.md` |

## Numbered decisions

Decisions carry ids and get cited by them (`C31`) from `CLAUDE.md` and from code comments. Adopt
this in a project that already uses it — a decision that can be pointed at from the code is one
that actually constrains behaviour, rather than one that has to be rediscovered.

Numbering is worth adopting in new projects too, for the same reason.

**When a decision is reversed, rewrite its row as current truth and add one line to a "retired"
section naming which decision replaced it.** The retired list is a redirect, not an archive — it
exists so someone who finds an old id in a code comment learns where the answer moved. Everything
else lives in git history.

## The gotchas ledger

A file the tool does not currently produce and probably should. It collects recurring traps —
deprecation warnings, framework behaviours that bite, mistakes made more than once.

Three layers, and every entry belongs to exactly one:

1. **Active rules** — forward-looking. Applies when writing new code. An entry stays here even
   after its original incident is resolved, if it still tells you what to do next time.
2. **Accepted risks** — deliberate trade-offs, low severity. "Know this", not "fix this".
3. **Archive** — historical record only; the value is in documenting a past incident.

When adding an entry, ask which of the three it is. Keep it to a line or two. **A long ledger
stops being read, and an unread ledger is worse than none** — it looks like coverage.

The trigger is mechanical: a warning appears → fix the call site, add one line, do not write it
again.

## Do not duplicate

The rule that matters most, and the one these directories get wrong as they grow: one fact, one
place. `CLAUDE.md` states rules and points at the detail; it does not restate what `decisions.md`
already says.
