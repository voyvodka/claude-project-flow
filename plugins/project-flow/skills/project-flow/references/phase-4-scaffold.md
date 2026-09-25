# Phase 4 — Scaffold

Goal: build the project's brain, so that any AI session in this repo — Claude Code, opencode, or anything else — starts already knowing what the four phases before it established.

**This phase writes no application code.** Not a boilerplate, not a `main.ts`, not a config file for a framework. Only context and tooling. Phase 5 writes code, after the user opens that gate.

## What gets produced

| File | Language | Purpose |
|---|---|---|
| `CLAUDE.md` | English | The main context source — identity, rules, pointer to `docs/README.md` |
| `AGENTS.md` | English | Pointer file so non-Claude tools land on the same context |
| `docs/README.md` | The documents' language | Index of everything under `docs/`, routed by task |
| `.claude/agents/*.md` | English | Project-specific subagents — few, or none |
| `.claude/skills/*/SKILL.md` | English | Only for genuinely repeated work |
| `.claude/rules/*.md` | English | Area-specific rules, loaded only when matching files are read — once `CLAUDE.md` would outgrow its budget |
| `.claude/settings.json`, `.claude/hooks/` | English | Checks that must run every time — usually one Stop hook, often none |

Start from `templates/project-CLAUDE.md` and `templates/project-AGENTS.md` (named with the
prefix so they are not mistaken for this plugin's own context files), and from
`templates/docs-README.md` for the index.

**If any of these files already exists, stop and ask before writing.** An existing `CLAUDE.md`,
`AGENTS.md` or `docs/` tree is someone's work, and it is usually the work of whoever will be most
annoyed to lose it. Read it, say in two or three lines what it currently covers and where it
disagrees with what this phase would write, then offer the choice: **merge** (keep their structure,
fold in what is missing), **replace** (their content moves to `docs/` first), or **leave it and
write alongside** (this tool's context goes in `docs/README.md` only). Never silently overwrite, and
never silently append either — a file with two "What this project is" sections is worse than either
version alone. Record which way it went in `00-state.md`, because the next session will otherwise
propose the same overwrite again.

**If the publication decision keeps AI tooling out of the repository**, everything in the table
above stays on the owner's machine: list each path in `.git/info/exclude`, never in `.gitignore`.
`.gitignore` is itself committed, so it would publish the very list it hides, and a rule written
into it can stop matching on a rename without any error. Make "nothing about AI tooling is
committed here" the first rule in `CLAUDE.md` — it covers commit messages and PR text as well as
files — and note in `00-state.md` that a fresh clone carries none of this context.

## CLAUDE.md

This is the file an AI reads first in every future session, so it is written for reading under a budget: dense, specific, and free of anything derivable from the code itself.

It covers:

- **What this project is** — two or three sentences, from `01-brief.md`.
- **Stack and why** — the choice plus the one-line reason from `02-decisions.md`. The reason prevents casual substitution.
- **Where the truth lives** — a pointer to `docs/README.md` plus the entry point (`00-state.md` first, then `02-decisions.md`). Not the map itself: write that into `docs/README.md`, which is created in this phase and is where every later addition gets listed.
- **Rules and conventions** — the project's actual constraints. Only ones that bite.
- **Standing assumptions** — the open `⚠️` list, and the instruction to ask the user rather than guess when work touches one.
- **Out of scope** — from `03-mvp.md`. This is what stops a future session from helpfully building something that was deliberately cut.
- **Verification** — the commands that prove a change works, and which of them a hook already runs. Omitted until a command exists.

Do not restate what the code plainly shows. Directory listings, obvious framework conventions, and generic best practices are noise; they push the useful lines out of a reader's attention.

**Budget: roughly 150 lines.** The whole file is read into every session, whatever the task, and
every line in it competes with the task for attention. An `@path` import does not help — the
imported file is loaded in full at the same moment. Where a rule applies to one area of the code
only — a legacy module, the mobile client, the migrations folder — it goes in
`.claude/rules/<area>.md` with a `paths:` list in its frontmatter, and loads only when a matching
file is read. `CLAUDE.md` keeps what applies everywhere. A rule file whose frontmatter does not
parse is dropped without an error, so read each one back once it is written.

## docs/README.md

From `templates/docs-README.md`. It is the index of everything under `docs/`, and it lives inside
the folder it indexes rather than in `CLAUDE.md` — so that adding a document and listing it are the
same motion, in the same directory. A map kept in `CLAUDE.md` is a different file in a different
place, and it goes stale the first time the folder outgrows the skeleton.

Two parts do the work, and only one of them is a listing:

- **A task router.** "If you are about to do X, read Y." A reader arrives with a job, not with a wish to browse a directory. Write one row per recurring job the project actually has, naming the area it touches; the generic rows in the template are the floor, not the set.
- **One row per file**, saying what it *answers*. Where a file has a maintenance rule of its own — a ledger that must stay one line per entry, a research note that goes stale — the row is where that rule belongs, because the row is what gets read before the file is opened.

State at the top what the folder is for: the things that cannot be read from the code. Then state
the converse — that nothing here restates what the code already says. That second sentence is what
keeps the folder from filling with prose nobody needs.

If `docs/` is private and `CLAUDE.md` is committed, say so in the index and say it plainly. A
reader who assumes otherwise will link to it from a public file, and every such link is dead for
everyone but its author.

## AGENTS.md

Per the user's decision, `CLAUDE.md` is the source and `AGENTS.md` points at it. Keep it minimal — a title, the one-line project identity, and an instruction to read `CLAUDE.md` and `docs/product/00-state.md` before doing anything.

Duplicating content between the two files is the one thing to avoid: two copies drift, and a reader cannot tell which one is stale.

## Checks that must run — hooks, not prose

**A rule that says "run the typecheck before you finish" is advice; a hook is a check.** Written
instructions of that kind are skipped exactly when the session is busiest, which is when they
matter. Where Phase 2 or 3 settled a verification command, wire the fast part of it into the
tooling rather than into `CLAUDE.md`:

- **A Stop hook** in `.claude/settings.json` that runs the fast checks — typecheck, format, lint —
  on the files the working tree changed, and blocks the end of the turn with the failure output.
  Skip it when nothing relevant changed, remember a diff that already passed so the same diff is
  not re-checked, and let the turn end if it blocks twice on an unchanged diff (`stop_hook_active`),
  or a failure the session cannot fix becomes a loop.
- **A git pre-push hook** for the slow suite, when there is one — skipped for pushes that carry no
  code (docs only, branch deletions). A slow check that fires on every push gets bypassed.

Then one line in `CLAUDE.md` saying what the hooks run, so a reader does not duplicate them in
prose. Right-size it like everything else: a project with no verification command yet gets no
hook, and a weekend script gets at most the Stop hook.

## Subagents and skills — the budget

This is where over-engineering enters, so it is explicitly bounded.

**Default: none.** A project needs no custom subagent until there is a specific, repeated, context-heavy task that a general agent handles worse.

**One exception clears the bar on its own: a single failure class that is invisible in review and fatal to the product.** Cross-tenant leakage in a multi-tenant product, fund movement in anything handling money, permission escalation wherever roles gate real access. These share a shape — the broken version looks exactly like the working version until the specific case that breaks it is constructed, and the author is the person least able to construct it, because the case they did not think of while writing is the same one they will not think of while testing. An auditor with its own mental model and no attachment to the implementation catches what self-review structurally cannot.

Where the research or the decisions identify such a class, propose an auditor for it and say plainly why. Do not fold it into the "default: none" instinct — that rule exists to keep out generic reviewers that duplicate what the base tool already does, not to keep out the one narrow check that stands between the project and a fatal defect.

Add one only when all three hold:

1. The task recurs across sessions — not once during setup.
2. It benefits from an isolated context (large search, focused review, bulk transformation).
3. A plain prompt would keep losing the same details.

Rough ceilings, to be undershot rather than met:

| Project size | Subagents | Skills |
|---|---|---|
| Small (script, single-purpose tool) | 0 | 0 |
| Medium (app with a handful of subsystems) | 0–2 | 0–1 |
| Large (multiple services, real team) | 2–3 | 1–2 |

Propose each one to the user with its justification and let them decline. "Might be useful later" is a decline. Something built in Phase 4 that no one uses in Phase 5 is pure cost — it is read into context on every session and pays back nothing.

The user can overrule the budget and ask for tooling you judged unnecessary. Build it, and build it properly — a grudging subagent is worse than none. But **record in `00-state.md` that it was built on request rather than on recommendation.** Six months on, someone inheriting the repo sees three agent files and reasonably concludes they were required; that one clause is the difference between them trusting the tooling and being misled by it.

**One writer.** A subagent this phase proposes reviews, audits or researches; it does not edit.
Give it read-only tools (`Read`, `Grep`, `Glob`, plus `Bash` only when it must run a check) and let
the main session make every change — two contexts editing the same files produce conflicts that
neither can see. Set `model:` to the cheapest model that does the job: a review or search pass
rarely needs the strongest one, and the fatal-class auditor above is the case that may.

Skills are for repeated *procedures* with a fixed shape — a release checklist, a domain-specific review pass, a code-generation convention. Not for knowledge; knowledge belongs in `CLAUDE.md` or `docs/`.

One case genuinely earns a skill: **a stack the AI writing the code gets predictably wrong.** If Phase 2 found that the chosen framework recently changed its idioms, or that a library's common examples are outdated, or that a pattern this project depends on is easy to write in a subtly broken way, encode the correct shape as a skill. That is a repeated procedure with a fixed shape, and it pays back on every increment. Note it in `02-decisions.md` next to the stack decision — a stack chosen *with* a mitigation is a different decision from one chosen without.

## Verify the handover

Run the four-item guarantee in `SKILL.md` against this repository, item by item. The honest framing: if it were handed to a competent stranger with no chat history, could they open `CLAUDE.md` and `00-state.md` and know what to do next?

If the project is a git repo, this is a natural commit point. Only suggest it — never run git commands unless the user asks.

**Before initialising a repository or making a first commit, re-read `profile/local-environment.md`.** The profile was read at the start of Phase 1 and is no longer in mind by the time this offer is accepted; identity and setup requirements recorded there apply at exactly this moment and nowhere earlier. Set what it requires as part of the same action, and say what was set.

Getting this wrong is quiet and expensive: the first commits carry whatever the machine's global configuration says, which may be an identity that belongs to a different context entirely. Correcting authorship afterwards means rewriting history, and nobody notices until the repository is somewhere public.

## Gate

The phase ends with the brain written and the file tree shown to the user.

Then ask the question that matters: the plan is recorded and the tooling is in place — start building the first increment from `04-roadmap.md`?

Wait. Phase 5 is the first phase that touches code, and it is the one gate that must never be assumed.
