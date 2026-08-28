# claude-project-flow

A Claude Code plugin that carries a project from *"I have a rough idea"* to working code through
six approval-gated phases — and refuses to write a line of application code until the first five
are done.

The problem it solves is the pair of failure modes an AI assistant falls into on a new project:
it starts building on a guess, or it asks questions forever. This fixes both with a **bounded**
checklist, evidence from real research instead of recall, and a set of documents that hold the
memory so the conversation does not have to.

## Install

```
/plugin marketplace add voyvodka/claude-plugins
/plugin install project-flow@voyvodka
```

The plugin is listed in a small [catalog marketplace](https://github.com/voyvodka/claude-plugins)
rather than being one itself, so a single registration covers every plugin from the same author and
`/plugin marketplace update voyvodka` refreshes all of them at once.

The `owner/repo` shorthand clones over SSH. Without an SSH key on the machine, use the HTTPS URL
instead — it needs no credentials for a public repository:

```
/plugin marketplace add https://github.com/voyvodka/claude-plugins.git
```

Then, in any project folder:

```
/project                       # start, or resume wherever the folder left off
/project a tool that does X    # start with a rough idea
```

Always the same command. It reads `docs/product/00-state.md` to work out whether this is a new
project, a resumption, or a request to advance — an empty folder, a half-finished plan, and an
existing codebase all route correctly.

## The six phases

| Phase | Does | Writes code |
|---|---|---|
| 0 · Detect | Classifies the folder, reports where things stand | No |
| 1 · Discover | Bounded question rounds against a fixed checklist | No |
| 2 · Research | Subagent fan-out: market, tech, dev environment | No |
| 3 · Decide | Findings become owned decisions and an MVP scope | No |
| 4 · Scaffold | `CLAUDE.md`, `AGENTS.md`, right-sized AI tooling | No |
| 5 · Build | Implements the roadmap in approved increments | Yes |

Every boundary is a gate the user opens. A phase can be skipped when it does not apply — but
never silently: it says what it is skipping, why, and writes that into the state file.

## What it leaves behind

```
<project>/
├── CLAUDE.md                 main context source
├── AGENTS.md                 pointer for non-Claude tools
├── docs/
│   ├── product/              00-state · 01-brief · 02-decisions · 03-mvp · 04-roadmap
│   └── research/             market · tech · devenv
└── .claude/
    ├── agents/               project-specific subagents — few, or none
    └── skills/               only for genuinely repeated work
```

All of it is meant to be committed. Someone who clones the repo — using Claude Code, opencode, or
anything else — reads `CLAUDE.md` and `docs/product/00-state.md` and continues from the same line
of thought. That handover is the point of the whole thing.

## The ideas it is built on

- **No application code before Phase 5 is approved.** If you ask for code earlier, it names what
  is still unknown and offers to fast-track the remaining phases rather than silently starting.
- **Documents are the memory, the conversation is not.** Anything confirmed is written down
  before moving on, as if the chat will be lost mid-sentence.
- **Ask, but bounded.** A fixed checklist with a round limit. Remaining unknowns become marked
  assumptions, raised again at the moment code depends on one — never more rounds of questions.
- **Research runs in subagents.** Each branch digs deep in its own context, writes straight to
  its own file, and returns ten lines. That is what keeps one long chat viable.
- **Right-size everything.** A weekend script gets a weekend-sized plan, two doc files and zero
  custom subagents. Preventing over-engineering is the reason this exists.
- **Never invent a fact.** Market numbers, competitor names, library versions and pricing come
  from research with a source, or they are written down as assumptions. Never from memory
  presented as fact.
- **Decisions are updated in place.** Git holds the history; the file always reads as current
  truth. A reversal is a sweep through everything that encoded the old choice, not a paragraph
  added below it.

## The developer profile

`plugins/project-flow/skills/project-flow/profile/` is the part you are meant to edit. It records what
you already know and reach for by default, one file per stack, so a project reads only what it
touches.

With it filled in, Phase 2 stops asking *"which stack?"* and starts asking *"is there a reason to
deviate from the default here?"* — faster, and a better question, because it forces a candidate to
beat the default on something the project actually needs.

**The files in this repository are one developer's answers, kept as a worked example rather than
as advice.** Replace them. A profile describing someone else is worse than an empty one, because
it will be trusted.

### Keeping your real profile out of git

`profile/local/` is gitignored, and any file placed there is read *instead of* the file with the
same name one directory up:

```
profile/infrastructure.md          committed — the template
profile/local/infrastructure.md    ignored     — the real one, read in preference
```

That is where hostnames, machine limits, git identity and repository paths belong. Two files
ship as templates for exactly this reason — `infrastructure.md` and `local-environment.md` — and
until one is filled in or overridden, the plugin treats its subject as genuinely open and asks
rather than assuming.

**This requires running the plugin from a copy you own.** A marketplace install is copied into a
versioned plugin cache, and that breaks the override in both directions: the clone it was built
from never contained `local/`, and a `local/` you create inside the cache is deleted by the next
update. Nothing errors when it fails — the templates are read instead, and the tool proceeds
trusting answers that describe a different developer, which is exactly the outcome the profile
warns about.

Two ways to have a real profile:

```
# clone it, and point a skills directory at the plugin — discovered in place, no cache copy
git clone https://github.com/voyvodka/claude-project-flow.git
ln -s "$PWD/claude-project-flow/plugins/project-flow" ~/.claude/skills/project-flow
```

or install from the marketplace and edit the committed `profile/` files directly, accepting that
an update overwrites them. If you do neither, treat every default in `profile/` as someone else's
and expect Phase 1 to confirm each one with you.

## It reviews itself

At every phase gate the tool asks whether anything went wrong **because of how it is written**,
separates structural failures from circumstantial ones, and logs them. The bar for acting is
evidence from a real project, not taste, and the preferred fix is to remove the cause rather than
add a reminder. It proposes changes; it never applies them to itself without approval.

`plugins/project-flow/skills/project-flow/feedback/observations.md` is that ledger, and
`plugins/project-flow/README.md` records why each version changed — reasoning, not a changelog. Both
include the findings that were **rejected**, and one that shipped and had to be reverted, because
the reason a plausible rule was wrong is the only thing that stops it coming back.

## Language

Conversation and everything under `docs/` follow the user's language. `CLAUDE.md`, `AGENTS.md`,
`.claude/**`, all code and all commit messages are always English.

## Repository layout

```
plugins/project-flow/              the plugin — see its own README for detail
```

## Licence

MIT — see [LICENSE](LICENSE).
