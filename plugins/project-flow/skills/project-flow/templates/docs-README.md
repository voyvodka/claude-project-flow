# docs — index

<!-- One line: what this folder is, and whether it is committed or private. If private, say so
     here and say it plainly — a reader who assumes otherwise will link to it from a public file. -->

**Keep this file current.** Anything added under `docs/` gets its row here in the same motion.
An index that lags is worse than none, because it reads as complete.

**When a decision or a state changes, the document moves before the code does.** A set that drifts
stops being trusted, and a set nobody trusts stops being read — at which point it is only cost.

---

<!-- What this folder is FOR, in a sentence or two: what cannot be read from the code. State the
     converse too — no document here restates what the code already says. That sentence is what
     stops the folder filling with prose nobody needs. -->

## What are you about to do

<!-- Route by task, not by file type. A reader arrives with a job, not with a wish to browse.
     Rows below are the ones every project has; add one per recurring job this project actually
     has, and name the *area* that job touches — that is the row someone will use. -->

| If you are… | Read first |
|---|---|
| Anything at all, in a new session | [`product/00-state.md`](product/00-state.md) — where things stand, what is open, what comes next |
| Proposing an approach or a plan | `00-state.md`, then [`product/02-decisions.md`](product/02-decisions.md) — ideas that look obvious are often already settled, with the reason and the accepted cost |
| Asked whether something exists or was rejected | `02-decisions.md` for what was settled against; the backlog, if there is one, for what is merely unbuilt |

## product/ — decisions, current

The set is fixed. These files stay current rather than accumulating history.

| File | Answers |
|---|---|
| [`00-state.md`](product/00-state.md) | Where things stand, open items, standing assumptions |
| [`01-brief.md`](product/01-brief.md) | Problem, audience, primary flow, success criterion, constraints |
| [`02-decisions.md`](product/02-decisions.md) | Why it is built this way — each decision with what was rejected and what it cost |
| [`03-mvp.md`](product/03-mvp.md) | What is in and out of scope, and what is parked |
| [`04-roadmap.md`](product/04-roadmap.md) | The build order as increments, and the progress ledger |

## research/ — evidence, dated, goes stale

<!-- Say here how claims are marked (verified versus assumed), so a reader knows what
     weight to give a number. Drop any row whose branch was skipped. -->

| File | Covers |
|---|---|
| [`market.md`](research/market.md) | Market and competitors |
| [`tech.md`](research/tech.md) | Stack candidates and the reasoning behind the pick |
| [`devenv.md`](research/devenv.md) | Development, testing, and deployment environment |

<!-- Sections below are for what the project actually grows. Delete the ones it does not.
     A heading with nothing under it is noise; a document with no row is the failure this
     file exists to prevent. -->

## Work-in-progress notes

Scoped to one piece of work, and disposable once it lands. Say which are still live and which
are finished — a stale plan read as current is worse than a missing one.

| Path | Covers | State |
|---|---|---|

## RFCs/ — design notes for specific changes

Mark superseded ones as superseded, in the row. Someone will otherwise implement one.

| File | Covers |
|---|---|
