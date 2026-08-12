# Observations

Evidence from real projects about how this tool behaves. See
[`../references/self-improvement.md`](../references/self-improvement.md) for what belongs here and
what the bar for acting on it is.

**This is a redirect, not an archive.** An applied entry collapses to a row naming where the fix
now lives; the incident that justified it stays in git history. A lesson kept here as prose is a
lesson that never fires, because nobody reads a log while working — which is the same defect this
file exists to catch. Once a change is in, the instruction file is where it belongs.

Open and rejected entries keep their full form. Rejected ones especially: the same idea comes back,
and the reason it was turned down is the only thing that stops it.

## Applied

| Finding | Class | Fixed in | Where the rule lives now |
|---|---|---|---|
| Records written only on success — a step dying mid-way left no trace, in two different phases | structural, seen twice | 0.1.1, 0.7.0 | `phase-1-discover.md`, `phase-5-build.md` — create and mark *before* starting |
| A research branch weighed "existing skills" that no checklist collected | dangling reference | 0.2.0 | `profile/`, and the Phase 1 item that feeds it |
| Five behaviours the trial produced without being told to | — | 0.2.1, 0.3.0, 0.3.1, 0.6.x | `phase-2-research.md`, `phase-3-decide.md`, `phase-4-scaffold.md` |
| A reversal added the new truth and left the old one standing four paragraphs below | structural | 0.5.0 | `SKILL.md` — Document hygiene |
| Two files held one fact; the second went stale | duplication | 0.8.1 | `phase-5-build.md` — the state file points at the roadmap instead of restating it |
| "Default: none" blocked an auditor that then found a cross-tenant account takeover | too blunt, found by being overruled | 0.9.0 | `phase-4-scaffold.md` — the invisible-and-fatal exception |
| Per-round state update never fired — and turned out to be ceremony, not neglect | over-specified | 1.5.1 | `phase-1-discover.md` — relaxed, not enforced |
| Git identity rule sat where it was read, not where it applied; the first commit carried the wrong author | never fires | 1.7.1 | `SKILL.md`, `phase-4-scaffold.md`, `phase-5-build.md` |
| Dependency versions written from recall against a "latest stable" rule with no method | structural | 1.7.2 | `profile/code-style.md` — resolve with the package manager |
| Decisions recorded individually and never read as a set; `--fetch` contradicted a read-only scope | structural, found by the tool itself | 1.9.0 | `phase-3-decide.md` — contradiction check before the gate |
| Two of four research branches returned no summary, and the instruction forbade reading the files instead | structural, found by the tool itself | 2.2.1 | `phase-2-research.md` — the file is the deliverable, the summary a convenience |
| "Success criteria" had no referent in a project that already shipped; phases ran against an outward goal the owner would not have chosen first | structural | 2.5.0 | `phase-1-discover.md` — item 4 splits when the MVP already shipped; `phase-0-detect.md` — what a codebase conceals |

Two rows are worth more than their fix. The git identity rule was **correct, prominent and indexed
as always-relevant, and still could not fire** — placement beat wording. And the `--fetch`
contradiction was caught by the tool at its own phase-gate prompt, which is this loop working as
designed rather than a defect found from outside.

## Open

### Phase 1 assumes the user arrives with a product idea

- **Project:** `new-idea` (Unity Asset Store, July 2026)
- **Class:** unsure — logged rather than fixed
- **What happened:** The project was deliberately inverted: the distribution channel and the
  constraints were settled, and the product itself was left for Phase 2 research to determine.
  `phase-1-discover.md` treats "problem" and "main flow" as blocking checklist items, so by
  construction neither could be answered. The phase deferred both to Phase 3 and wrote the reason
  into `01-brief.md` — correct behaviour, but nothing in the instructions asked for it.
- **Instruction involved:** `references/phase-1-discover.md` — the checklist
- **Proposed change:** none yet — needs a second sighting
- **Status:** logged

Worth waiting on rather than fixing. The channel-first shape ("I know where I want to sell, tell me
what to build") is a real and repeatable one, which argues structural. But the phase handled it well
unprompted, and a rule added to bless a deviation the tool already makes correctly is a rule that
earns nothing. The thing to watch on a second sighting is whether a different session instead
pressures the user to invent a product on the spot — that would be the actual failure, and it has
not been observed.

Also worth pinning if it recurs: this phase turned "I don't want operational burden" into "2-4 hours
per month", making a vague user constraint into a threshold Phase 2 can answer pass/fail. That is
the `code-style.md` lesson — a requirement without a method is a wish — applied spontaneously to a
user constraint rather than a profile rule, which is a place nothing had specified it for.


## Rejected

### A gate instruction needs a mandatory landing place — *shipped in 2.3.0, reverted in 2.3.1*

- **Project:** `new-idea` (Unity Asset Store, July 2026)
- **What was observed:** A user instruction issued at a phase gate — run a feasibility spike earlier
  than planned — never appeared in any project document across four attempts, and the phase never
  said it had declined it either.
- **Proposed change:** `SKILL.md` gains a rule that a gate instruction becomes an increment, a
  decision, or an assumption before the gate closes, or is refused out loud.
- **Why rejected:** the instructions were being relayed into the session by hand from a second
  conversation, and it later emerged that the relay itself was the lossy part — several were never
  sent at all. The phase was never shown to have dropped anything. The rule was added to the
  always-loaded file on evidence that did not survive contact with the actual cause.

Kept because the idea will come back, and because the way it failed is more instructive than the
idea. Two of this file's own standards were broken to ship it. **"One project is one data point"**
— this was not even that, since the failing component turned out to sit outside the tool. And
2.2.0's own new rule, **a fix is applied when its rule has been seen to fire, not when the text is
saved** — the rule was written, shipped and versioned without a single observation of it working.

The general shape worth remembering: **an explanation that indicts the system you are holding is
the one to distrust first.** Four failures were read as four data points about the phase, when they
were four data points about a channel that was never examined because it was not part of the thing
being studied.

If it recurs where the instruction is *known* to have arrived, that is a real first sighting and
this entry is the head start.
