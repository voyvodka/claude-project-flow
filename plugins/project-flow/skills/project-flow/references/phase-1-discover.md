# Phase 1 — Discover

Goal: understand the project well enough to research it, and no better. This phase writes `docs/product/01-brief.md`.

The failure mode this phase exists to prevent is not "too few questions" — it is an AI that starts building on a guess. The second failure mode, equally real, is an AI that asks forever. The checklist and the round limit are what keep both out.

## The checklist

**Blocking** — the phase does not end until all six are answered.

| # | Item | What must be answered |
|---|---|---|
| 1 | Problem | Which real problem, whose problem, how it is solved today |
| 2 | Users | Who, roughly how many, how they are reached |
| 3 | Main flow | The user's number-one task, start to finish |
| 4 | Success criteria | One measurable sentence for "the MVP worked" — but see below when the MVP already shipped |
| 5 | Out of scope | What the MVP will explicitly *not* do |
| 6 | Constraints | Time, budget, team size, mandatory technologies |
| 6b | Existing skill | What the team can already build in at full speed — and who or what actually writes the code |

**Non-blocking** — if unanswered, record as an assumption and move on.

| # | Item |
|---|---|
| 7 | Data and external integrations |
| 8 | Expected scale |
| 9 | Delivery target (web / mobile / desktop / CLI, and where it deploys) |
| 10 | Identity and permissions |
| 11 | Revenue model |
| 12 | Maintenance — who keeps it alive, for how long |

Item 5 is the one users skip and the one that saves the most work. Never let the phase end without it. "Everything is in scope" is not an answer; push back once with concrete examples of things that could be cut.

### Item 4 when the MVP already shipped

"Did the MVP work" has no referent in a project with a year of release history behind it, and the
nearest thing that fits the wording is usually an outward goal — growth, adoption, reach. Settle
for that and the phase closes on a criterion that is **downstream of one nobody asked for.**

So in an existing-code project item 4 is two answers, in this order:

1. **The owner's bar for the product being fit to push.** Not a feature list — the standard below which they will not point anyone at it. Press for components; "when it feels right" is not yet an answer, and the components are usually specific once asked for.
2. **The outward goal**, which the first one governs. Everything aimed outward waits behind it.

Getting these the wrong way round is expensive and quiet: research, scope, and increments all
order themselves against the outward goal, and the bar only surfaces at the moment something is
about to be published — by which point the work is done and parked.

### Item 3 when there are several roles

Many systems have no single main flow — a member, a receptionist, a manager, and a cashier each have their own. Do not force them into one flow, and do not answer with a list of one flow per role. Both lose the plot.

Instead:

1. Build a **role table** first: who each role is, what they do, which interface they touch.
2. Then pick **one primary flow** — the system's number-one job, the thing that repeats most and that the product would be worthless without. Write that one end to end.

The remaining roles' flows belong to Phase 3's scope discussion, not here. Picking the primary flow is what makes the MVP cut possible later; a project that never picks one keeps every role at equal priority and ships nothing.

### Item 6b — existing skill

Read `profile/README.md` before asking anything. It already answers this for most projects, so do
not re-ask what it states. Confirm it instead, in **one question**, folded into a round:

> "Profile says <known stack> and defaults to <default for this project type>. Does that
> hold for this project?"

Three answers to expect:

- **Yes** — record it and move on. This is the common case and it should cost one line.
- **Yes, but someone else is involved** — the profile describes one developer. If a
  collaborator or a client team will build or inherit this, their skills matter more than
  the profile's. Capture what is known about them.
- **No** — the project has its own constraints. Record them and treat stack selection as
  fully open in Phase 2.

Write the outcome into `01-brief.md` under constraints. Phase 2's tech branch reads it from
there, not from the profile — so a project that overrode the profile stays overridden even if
the profile changes later.

Record **who or what writes the code** alongside it. If an AI writes most of it, the human's
own fluency stops being the only thing that matters and stack selection gains a criterion it
would otherwise never get — Phase 2 acts on this, so it has to reach the brief.

## Rounds

**Before the first question**, create `docs/product/00-state.md` from `templates/00-state.md` with the phase set to 1 and everything else empty, and create `docs/product/01-brief.md` from its template. Both files then grow as answers arrive.

Do not defer this to the end of the phase. A discovery session that dies during round two must still leave a folder that the next session can read and resume — that is the whole point of the state file, and it cannot do its job if it only appears once the phase has already succeeded.

Ask in rounds of **at most 3–4 questions**, using `AskUserQuestion` with concrete, mutually exclusive options wherever the answer space is bounded. Open-ended prose questions are fine when the answer genuinely cannot be enumerated — the problem statement usually cannot be.

Each round:

1. Pick the highest-value **unanswered blocking** items. Blocking always outranks non-blocking.
2. Ask. Never ask something the user already answered, and never ask something derivable from the folder scan.
3. Write the answers into `01-brief.md` immediately — not at the end of the phase.
4. Touch `00-state.md` only when something lands that `01-brief.md` does not hold — a new
   assumption, or a phase-level decision such as skipping a research branch. The state file has to
   be right when the phase ends and has to exist from the start; between those it does not need
   restating what the brief already carries.
5. Close the round with a short **settled / still open / assumed** summary.

Aim to finish blocking items within **three rounds**. If a fourth is needed because answers keep
opening new ground, say so explicitly rather than drifting into it.

**Four rounds is the ceiling.** At the end of the fourth, stop asking. Every blocking item still
open becomes a marked assumption in `01-brief.md` with the best available answer and the reason it
is unresolved, and Phase 2 researches it instead. Say plainly which items converted and why.

The ceiling is the point, not a formality: answers that keep opening new ground are the signal that
the question is being *discovered* rather than *answered*, and another round buys another round.
Research is the cheaper instrument for a genuinely open question — a marked assumption that Phase 2
tests beats a fifth round the user has stopped reading.

## Closing the checklist

When the blocking items are done, walk items **7 through 12 one at a time** before opening the gate. Each one gets a row in the "Ek bilgiler" table of `01-brief.md`, and every row is filled — with an answer, or with a marked assumption.

This step is not optional and it is not satisfied by the information appearing "somewhere in the document". Answers scattered across prose, or buried inside the assumptions table, read as complete while leaving real gaps: an unanswered row is only visible when there is a row to be empty. Identity and permissions, and external integrations, are the two that vanish this way most often — and both are expensive to discover late.

If an item genuinely does not apply — no revenue model for an internal tool — write "yok / uygulanmaz" with the reason. That is an answer. A blank is not.

## Assumptions

Any non-blocking item still unanswered when blocking items are complete gets written as:

```
⚠️ VARSAYIM: <what was assumed> — <why this was assumed> — <what breaks if it is wrong>
```

Assumptions are recorded in both `01-brief.md` (in context) and `00-state.md` (as a running list). They are never deleted silently. When Phase 5 touches code that depends on an assumption, that is the moment to ask the user to confirm it — the third field above is what tells you it matters.

## Escape valve

The user can end the phase at any point with "yeter" / "enough" / "proceed with assumptions". Honor it immediately: convert every open item, blocking included, into a marked assumption and move to the gate. Note in `00-state.md` that discovery was cut short and which blocking items were assumed — that list is the first thing to revisit if the project goes sideways.

## Right-sizing

Read the scale from the answers, not from ambition. A personal script, an internal tool for five people, and a product aimed at paying customers deserve very different amounts of process.

For a small project, say so out loud and compress: fewer questions, no market research branch in Phase 2, two documents instead of five, no custom subagents in Phase 4. Proposing the full apparatus for a weekend script is exactly the over-engineering this tool is supposed to prevent.

**"Two documents" means these two**, so the later phases know where to write:

| Compact file | Absorbs | Written by |
|---|---|---|
| `docs/product/00-state.md` | unchanged — always exists | every phase |
| `docs/product/01-brief.md` | `02-decisions.md` — decisions become a `## Kararlar` section at the end | Phases 1 and 3 |
| `docs/product/03-mvp.md` | `04-roadmap.md` — the phased plan becomes a `## Yol haritası` section | Phases 3 and 5 |

Record the choice in `00-state.md` as `Belge düzeni: kompakt` on the first line that mentions layout.
Phases 3, 4 and 5 name `02-decisions.md` and `04-roadmap.md` directly; when the layout is compact,
write to the absorbing file and its section instead, and say so once rather than silently. Do not
invent a third shape — it is five files or these two, so that a reader who knows one project's
layout knows every project's.

## Gate

The phase ends with:

- All six blocking items answered or explicitly assumed.
- Items 7–12 each carrying a filled row in the "Ek bilgiler" table — no blanks.
- `01-brief.md` written, using the template's section set and no invented top-level sections.
- `00-state.md` updated: phase, settled items, open items, assumption list.
- A short recap to the user and a clear question — proceed to research?

Do not start Phase 2 in the same breath. Wait.
