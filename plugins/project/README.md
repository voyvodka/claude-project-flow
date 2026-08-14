# project

One command — `/project` — that carries a project from "I have a rough idea" to working code.

The problem it solves: an AI that starts building on a guess, and an AI that asks questions
forever. It fixes both with a bounded checklist, evidence from real research, and a set of
documents that hold the memory instead of the chat.

## Usage

```
/project                       # start, or resume wherever the folder left off
/project a tool that does X    # start with a rough idea
```

Always the same command. It reads `docs/product/00-state.md` to work out whether this is a
new project, a resumption, or a request to advance — an empty folder, a half-finished plan,
and an existing codebase all route correctly.

## Phases

| Phase | Does | Writes code |
|---|---|---|
| 0 · Detect | Classifies the folder, reports where things stand | No |
| 1 · Discover | Bounded question rounds against a fixed checklist | No |
| 2 · Research | Subagent fan-out: market, tech, dev environment | No |
| 3 · Decide | Findings become owned decisions and an MVP scope | No |
| 4 · Scaffold | `CLAUDE.md`, `AGENTS.md`, right-sized AI tooling | No |
| 5 · Build | Implements the roadmap in approved increments | Yes |

Every phase boundary is a gate the user opens. Phases can be skipped when they do not apply,
but never silently.

## What it produces

```
<project>/
├── CLAUDE.md                 EN · main context source
├── AGENTS.md                 EN · pointer for non-Claude tools
├── docs/
│   ├── product/              00-state · 01-brief · 02-decisions · 03-mvp · 04-roadmap
│   └── research/             market · tech · devenv
└── .claude/
    ├── agents/               project-specific subagents — few, or none
    └── skills/               only for genuinely repeated work
```

All of it is meant to be committed. Someone who clones the repo — using Claude Code, opencode,
or anything else — reads `CLAUDE.md` and `docs/product/00-state.md` and continues from the
same line of thought. That is the point of the whole thing.

## Design rules

- **No application code before Phase 5 is approved.** Phases 0–4 produce documentation and
  tooling only.
- **Documents are the memory, not the conversation.** Anything confirmed is written down
  before moving on.
- **Research runs in subagents.** Each branch digs deep in its own context and returns ten
  lines, so one long chat stays viable.
- **Unknowns become marked assumptions, not more questions.** Assumptions are raised again
  at the moment code depends on them.
- **Right-size everything.** A weekend script gets a weekend-sized plan and zero custom
  subagents. Avoiding over-engineering is the reason this exists.
- **Decisions are updated in place.** Git holds the history; the file always reads as
  current truth.

## Language

Conversation and `docs/**` follow the user's language. `CLAUDE.md`, `AGENTS.md`, `.claude/**`,
and all code are always English.

## Layout

```
plugins/project/
├── commands/project.md                     thin entry point
└── skills/project-flow/
    ├── SKILL.md                            directives, state contract, routing
    ├── profile/                            EDIT THIS — one file per stack, README indexes
    ├── references/phase-0-detect.md        loaded one at a time, per phase
    ├── references/phase-1-discover.md
    ├── references/phase-2-research.md
    ├── references/phase-3-decide.md
    ├── references/phase-4-scaffold.md
    ├── references/phase-5-build.md
    └── templates/                          document skeletons
```

Research uses `general-purpose` subagents with prompts defined in `phase-2-research.md`,
rather than plugin-level agent definitions — those would register globally in every project,
which is a cost this plugin does not need to impose.

## Developer profile

`skills/project-flow/profile/` records what the developer already knows and what they reach for
by default. `README.md` indexes it; each stack gets its own file, so a project reads only what it
touches. Without it, stack selection runs blind to the single heaviest factor in it.

The most durable entries are not package lists but **pointers to reference implementations** —
"a web app follows the shape of *this* repository". Those stay true as the repositories evolve,
where a list of versions goes stale the month after it is written.

With a filled profile, Phase 2 stops asking "which stack?" and starts asking "is there a
reason to deviate from the default here?" — which is both faster and a better question, since
it forces a candidate to beat the default on something the project actually needs.

Phase 1 confirms the profile applies before Phase 2 uses it, and writes the outcome into the
project's own brief. A project that overrode the profile stays overridden even if the profile
changes later.

The files here are a worked example, not advice — replace them. Anything machine-specific goes in
`profile/local/`, which is gitignored and read *instead of* the file of the same name one
directory up. See the repository README for the split — **and for why that split needs the plugin
to run from a clone rather than from a marketplace install.**

## Status

The authoritative version is in `.claude-plugin/plugin.json`. What follows is why each change was
made, newest first — reasoning, not a changelog.

Version 2.4.0 — published. Going public forced the split the profile always implied but never
made: `profile/` held a specific machine, a specific server with its open ports, two e-mail
addresses and a handful of workplace repository paths, all of it load-bearing for one person and
useless-to-harmful for anyone else. The committed files are now templates carrying the *questions*
— what to record about hosting, headroom, backups, mail, git identity — while the answers live in
an ignored `profile/local/`, read in preference to them. The rule sits in `SKILL.md` rather than
in `profile/README.md`, because a local `README.md` would otherwise override the very instruction
that explains local overrides.

Versions 2.3.0 and 2.3.1 — a rule shipped and reverted in one day, which is the most useful entry
here. A user instruction issued at a phase gate appeared to vanish four times running, so `SKILL.md`
gained a rule forcing gate instructions to land somewhere. It then emerged that the instructions
were being relayed by hand from a second conversation and several were never sent at all: the
lossy component was outside the tool entirely. Reverted. Two of the project's own standards had
been broken to ship it — "one project is one data point", and 2.2.0's own new rule that a fix is
applied when it has been *seen to fire*. The entry stays in `feedback/observations.md` under
Rejected, because the shape generalises: an explanation that indicts the system you are holding is
the one to distrust first.

Version 2.2.0 — the tool applied its own duplication rule to itself. `feedback/observations.md`
had grown to 202 lines with nine entries, all of them applied and none collapsed, in direct breach
of the instruction it lives under. It is now a redirect ledger: one row per finding, naming the
file where the rule actually fires. The prose is in git history, which is where a resolved incident
belongs. Checking first proved the obvious restructure wrong — a "lessons" section would have been
a third copy, since every lesson was already in its instruction file. Only two had no home
anywhere, and both moved into `self-improvement.md`: the test for when a user overruling the tool
counts as a defect, and the rule that a fix is applied when it has been *seen to fire*, not when
the text is saved.

Versions 1.2.0 through 2.1.1 — the tool met real projects and mostly lost. A second trial on a
small Go CLI proved right-sizing works: product docs came out a third the size of the SaaS trial's,
one research branch instead of four, zero custom agents. Along the way the profile split out the
local machine from the server, the repository-layout convention landed, README generation moved to
MVP close with separate internal and public shapes, and the phase files learned to re-read the
profile at the moment a rule applies rather than trusting Phase 1 to have remembered it. 2.1.1 was
a deduplication pass: the handover checklist and the reversal rule had each been written out in
three places, one of which was the rule against writing things twice.

Version 1.1.0 — the architecture itself is now written down, not just described. `profile/` carries
the concrete response envelope, list contract and base-controller hierarchy as code; the React
directory layout, shared-component inventory and the specific rules that keep duplication out; and
a Next.js file that exists to prevent the one mistake that matters there — transplanting the SPA
architecture into it instead of using the framework as designed. Four preferences were also
sharpened from absolutes into what they actually are: doc summaries belong on shared and general
methods rather than every method, the TypeScript pin is a temporary block with a named unblock
condition rather than conservatism, bun is preferred but decided per project on measured evidence,
and comments stay minimal with critical ones welcome.

Version 1.0.0 — the profile stopped pointing at reference repositories and absorbed them. Naming,
comment policy (sparse by default, mandatory one-line summaries, controller actions exempt),
safety rails, endpoint and envelope conventions, UTC-everywhere, tenant isolation, rotating-refresh
auth, the UI rules that get re-litigated, and the personal/workplace infrastructure split are now
written into `profile/` rather than left to be rediscovered by reading code.

Also new: a self-improvement loop. The tool asks at phase gates whether anything failed *because
of how it is written*, distinguishes structural failures from circumstantial ones, and logs to
`feedback/observations.md` — seeded with the trial's own findings as worked examples. It proposes
changes and never applies them itself; the bar is evidence, not taste, and removing a cause beats
adding a reminder.

Version 0.9.0 — the trial's sharpest lesson, and one against the tool's own judgement. The
tool declined to build custom subagents for a solo-developer project; the user overruled it
and asked for them anyway. The tenant-isolation auditor then found a cross-tenant account
takeover that the increment's own tests could not have caught: those tests used two users in
two tenants, while the flaw needed one user present in both. It was dormant that day and would
have opened with the next increment's profile-editing endpoint. "Default: none" now carries an
explicit exception for a failure class that is invisible in review and fatal to the product —
the author is the person least able to construct the case they did not think of.

Version 0.8.0 — verification held up under the hardest test available: tenant isolation was
confirmed by connecting to the database directly as the application role, with the application
layer out of the picture, covering the write path and the unset-tenant case rather than only
the happy read. Documentation did not hold up. Two causes, both now specified: the session task
list had become a parallel progress tracker and was being fed instead of the durable roadmap,
and an architectural decision made during implementation — a deliberate, deliberately narrow
exception to the project's own isolation rule — was recorded in a code comment and nowhere a
reader could find it without already knowing which file to open.

Version 0.7.0 — the second defect, and the same class as the first one found in Phase 1: a
record written only on success. The progress ledger was updated after an increment finished,
so a half-built increment read as "not started" — with a running database and a created
migration already on disk, which is far more dangerous to build on top of blindly than an
empty folder. Increments are now marked in-progress before any code is written.

Version 0.6.x — two behaviours the trial produced spontaneously, now specified. When research
cannot settle a decision, Phase 3 proposes a **spike**: a timeboxed experiment answering one
question, with a stated pass/fail and what each outcome decides. And when a branch contradicts
something the tool told the user earlier — including its own framing hypothesis — the summary
leads with the correction rather than quietly dropping it; when a user's objection was
well-founded but the evidence did not change the answer, both halves get said.

Version 0.5.0 — the first real defect the trial exposed in the tool itself. When a stack
decision was reversed mid-build, the new truth was written correctly but an older rule
encoding the old choice was left standing beside it, in the same file. Reversals are now
specified as a sweep rather than an addition: every earlier statement that encoded the old
decision must be rewritten or deleted, and the phase must say which documents it touched.
Stale statements tend to be the more specific of the two, which makes them the ones a reader
follows.

Also in 0.4.x: stack selection accounts for **who writes the code**. When an AI writes
most of it, the deciding question stops being what the developer knows and becomes what the
developer and the AI move fastest in together: training-data representation, API stability,
how verifiable the output is without running it, and how readable the result stays for the
human still reviewing it. The profile records the development model, Phase 1 carries it into
the brief, Phase 2 weighs it as a first-class criterion, and Phase 4 may encode a mitigating
skill when the chosen stack is one the AI gets predictably wrong.

Version 0.3.1 — Phase 4 trialled. The budget rule worked: the tool declined to build custom
subagents for a solo-developer monorepo, and when the user overruled it, produced narrow,
project-specific tooling rather than generic filler — and recorded that it was built on
request rather than on recommendation. That last behaviour is now pinned in the spec instead
of left to judgement.

Version 0.3.0 — Phase 3 trialled: eleven decisions recorded with sources, a six-increment
roadmap ordered by risk rather than convenience, and verification criteria that are real tests
rather than checkboxes. The scope-versus-deadline tension was scheduled for measurement instead
of being declared solved. Fixes: an "accepted cost" line added to the decision format, the
rejected-alternatives line made non-blankable, and assumption promotion extended to cover
assumptions settled as a side effect of another decision.

Version 0.2.1 — Phase 2 also trialled on the same project: four branches, ~2,250 lines of
sourced research, and three cross-branch conflicts that no single branch could have found.
Research and decision stayed separated, and the summary led with the finding that invalidated
the user's own core premise. Fixes from that trial: the dead-ends section is now a required
opening rather than an emergent habit, verification markers sit next to claims instead of in
a section at the end, and calculations must separate sourced inputs from estimates.

Phase 0 and Phase 1 trialled against a real project (a multi-tenant gym
management SaaS). Both behaved as designed: the folder was classified correctly, discovery
finished in three rounds, out-of-scope was pushed on properly, and a scope-versus-deadline
contradiction was recorded rather than smoothed over.

Fixes from that trial, all in Phase 1: the state file is now created before the first
question instead of at the gate; non-blocking checklist items are a fixed table that cannot
be left blank; document hygiene rules added to stop the tool's own vocabulary leaking into
project documents; multi-role systems get an explicit role-table-then-one-primary-flow rule.

Phases 2 through 5 are untested.
