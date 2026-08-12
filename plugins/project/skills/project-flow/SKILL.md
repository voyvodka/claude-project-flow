---
name: project-flow
description: Drives a project from a rough idea to shipped code through six approval-gated phases — detect where the folder stands, interrogate the idea with a bounded checklist, research market and stack via subagents, lock decisions into docs/, scaffold AI tooling, then implement in increments. Use when the user runs /project, or asks to start, scope, plan, or resume a project in a folder.
version: 0.1.0
---

# Project Flow

One command (`/project`) that carries a project from "I have a rough idea" to working code without guessing at any step.

## Prime directives

Breaking any of these breaks the tool.

1. **No application code before Phase 5 is approved.** Phases 0–4 produce documentation and AI tooling only. If the user asks for code earlier, name what is still unknown and offer to fast-track the remaining phases instead of silently starting.
2. **Documents are the memory, the conversation is not.** Every fact the user confirms goes into `docs/product/` before moving on. Write as if this chat will be lost mid-sentence — because for the person who inherits the repo, it was.
3. **Ask, but bounded.** Phase 1 runs off a fixed checklist with a round limit. Remaining unknowns become marked assumptions, never more rounds of questions.
4. **The user opens every gate.** Never advance a phase without explicit approval. State what the next phase will do, then wait.
5. **Right-size everything.** This tool exists to prevent over-engineering. A weekend script gets a weekend-sized plan, two doc files, and zero custom subagents. Scale the output to the project, not to the tool's capacity.
6. **Improve the tool from evidence, never from taste.** Projects run through this tool are the
   only evidence about whether it works. Use it — but a rule added for every irritation makes a
   document too long to read, and an unread instruction is worse than a missing one. See
   `references/self-improvement.md` for the bar.
7. **Never invent a fact.** Market numbers, competitor names, library versions, and pricing come from research with a source, or they are written as `⚠️ VARSAYIM` / `⚠️ ASSUMPTION`. Never from memory presented as fact.

## Language

- **Conversation with the user** — the user's own language.
- **`docs/product/**` and `docs/research/**`** — the user's own language. Humans read these and decide from them.
- **`CLAUDE.md`, `AGENTS.md`, `.claude/agents/**`, `.claude/skills/**`, all code, identifiers, and commit messages** — always English, regardless of conversation language.

If the project already has documents in a given language, match that language rather than switching.

## Document hygiene

The documents belong to the project, not to this tool. Someone reading them a year from now should not be able to tell which tool produced them.

- **Never leak this tool's vocabulary.** No checklist item numbers, no phase numbers in headings, no "madde 9 · cevaplandı". Internal scaffolding stays internal. Referring to a phase inside a note about *when* something will be decided is fine; naming one in a section heading is not.
- **The template's section set is fixed.** Fill the sections that exist. Do not invent new top-level headings for content that belongs in an existing one — that is how the same fact ends up written twice, in two versions, with no way to tell which is current.
- **A reversal is a sweep, not an addition.** When a decision changes, every earlier statement that encoded the old one gets rewritten or deleted — not left standing next to the new one. The stale statement is usually the more specific of the two, which makes it the one a reader follows.
- **Write once.** If something is already stated in another document, link to it rather than restating it. `00-state.md` is the deliberate exception: it summarizes, and its summaries carry a pointer to the source.
- **Date every document.** A stale document that admits its age is far safer than one that looks current.

## The developer profile

`profile/README.md`, next to this file, records what the developer already knows and reaches for
by default. **Read it at the start of Phase 1** — it indexes the rest and says which files a
given project needs.

It supplies defaults, never verdicts: Phase 1 confirms they apply, Phase 2 tests them against
what the project actually needs. If it is empty or still full of placeholders, say so once and
treat stack selection as fully open rather than inventing a background.

**`profile/local/` overrides `profile/`.** Where `profile/local/<name>.md` exists, read it
*instead of* `profile/<name>.md` — never both. That directory is not committed, and it is where
hostnames, machine limits, git identity and repository paths live, so the committed files can
stay generic. Check for it whenever you are about to read a profile file.

**Re-read the relevant file at the moment it applies**, not only at Phase 1. A rule about
initialising a repository is useless four phases after it was read.

## The state file

`docs/product/00-state.md` is the single source of truth for where a project stands. It is the first file created and the last file touched in every invocation.

Contract:

- It always records the **current phase**, what is **settled**, what is **open**, and every **outstanding assumption**.
- Every phase updates it before handing control back to the user.
- On a fresh invocation it is read first — it is how `/project` knows whether this is a new project, a resumption, or a request to advance.
- It is the first file a new collaborator (or a different AI tool) should read.

If `docs/product/00-state.md` disagrees with the conversation, the conversation is right and the file is stale — fix the file immediately.

## Routing

Every `/project` invocation follows the same opening move:

1. Read `docs/product/00-state.md` if it exists.
2. If it does not exist, run **Phase 0** to classify the folder.
3. Announce in one or two sentences where the project stands and which phase comes next.
4. Get the user's go-ahead, then load the reference file for that phase and follow it.

Load **only** the reference file for the phase being worked. Do not preload the others.

| Phase | Reference | Purpose | Writes code |
|---|---|---|---|
| 0 · Detect | `references/phase-0-detect.md` | Classify the folder, find where we left off | No |
| 1 · Discover | `references/phase-1-discover.md` | Bounded question rounds against a fixed checklist | No |
| 2 · Research | `references/phase-2-research.md` | Subagent fan-out: market, tech, dev environment | No |
| 3 · Decide | `references/phase-3-decide.md` | Turn findings into confirmed decisions and an MVP scope | No |
| 4 · Scaffold | `references/phase-4-scaffold.md` | Project `CLAUDE.md`, `AGENTS.md`, right-sized AI tooling | No |
| 5 · Build | `references/phase-5-build.md` | Implement the roadmap in approved increments | Yes |

At phase gates and at increment close, ask once whether anything went wrong **because of how this
tool is written** — and follow `references/self-improvement.md` if it did. Usually nothing did,
and that is the end of it. This tool never edits itself without the user's approval.

Phases are ordered but not rigid: if the user has already settled the stack, Phase 2's tech branch is skipped and recorded as "user-supplied". Skipping is allowed; skipping *silently* is not — say what you are skipping and why, and note it in `00-state.md`.

## Target file layout

Everything this tool produces lives in the project folder and is meant to be committed.

```
<project>/
├── CLAUDE.md                    EN · main context source: identity, rules, pointer to docs/README.md
├── AGENTS.md                    EN · pointer to CLAUDE.md for non-Claude tools
├── docs/
│   ├── README.md                index of everything under docs/ and what each file answers
│   ├── product/
│   │   ├── 00-state.md          where we are, what is open, standing assumptions
│   │   ├── 01-brief.md          problem, users, main flow, success criteria, out of scope
│   │   ├── 02-decisions.md      confirmed decisions, updated in place
│   │   ├── 03-mvp.md            MVP scope and what comes after
│   │   └── 04-roadmap.md        phased build plan and progress
│   └── research/
│       ├── market.md            market and competitors
│       ├── tech.md              stack candidates and the reasoning behind the pick
│       └── devenv.md            development, testing, and deployment environment
└── .claude/
    ├── agents/                  EN · project-specific subagents (few, or none)
    └── skills/                  EN · only for genuinely repeated work
```

`docs/product/` and `docs/research/` are deliberately separate: research is evidence with sources and goes stale; product docs are decisions and stay current.

**The index lives in `docs/README.md`, not in `CLAUDE.md`.** A map kept in `CLAUDE.md` is a
different file in a different directory from the document being added, so it is not updated, and a
folder that outgrows the skeleton above ends up with a map naming a fraction of what is there —
which reads as complete. Keeping the index inside the folder it indexes puts adding a file and
listing it in the same place. `CLAUDE.md` points at it and names the entry point (`00-state.md`)
and nothing more. This matters most when `docs/` is private and `CLAUDE.md` is committed: every
note added would otherwise touch a public file.

Adding anything under `docs/` means adding its row to `docs/README.md` in the same breath.

## Handover guarantee

The point of this tool is that someone else — or the same person on another machine, using Claude Code or opencode or anything else — can clone the repo and continue from the same line of thought.

That holds only if, at the end of every phase:

- `00-state.md` answers "where are we and what is next" without reading any chat history.
- `02-decisions.md` answers "why is it built this way" for every non-obvious choice.
- `CLAUDE.md` answers "what do I need to know before touching this code".
- Nothing important exists only in the conversation.

Before ending any turn, check those four. If one fails, fix it before replying.
