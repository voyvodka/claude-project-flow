# Phase 5 — Build

Goal: implement `04-roadmap.md` one increment at a time, keeping the documents true as the code appears.

This is the only phase that writes application code, and it starts only after the user has explicitly opened the gate at the end of Phase 4.

## The loop

For each increment in `04-roadmap.md`, in order:

1. **State the increment** — what it delivers, what it touches, how you will know it works. Two or three lines.
2. **Check the assumptions it depends on.** If it touches a standing `⚠️`, ask the user now. This is precisely the moment the assumption list was built for.
3. **Get approval to start.** For the first increment this is a real decision point; later ones can be lighter once a rhythm is established, but never silent.
4. **If a repository is being initialised here rather than in Phase 4**, the same rule applies: re-read `profile/local-environment.md` first and set what it requires. See `phase-4-scaffold.md`.
5. **Mark it started before writing anything.** Set the increment to in-progress in `04-roadmap.md`, which is the ledger of record once Phase 5 begins. `00-state.md` **points** at the active increment rather than restating it — "Artım 3 · `04-roadmap.md`" and nothing more. Two files describing the same position is two files to keep in step, and the second one always loses.

   The ledger must never say "not started" while there is half-built work on disk. A session that dies mid-increment leaves a next session reading "not started" against a populated repository — and a running database, a created migration, and a half-finished module are far more dangerous to build on top of blindly than an empty folder is. Records that are only written on success cannot describe a failure, which is the moment they matter most.
6. **Build it.** Use the task tools for the steps *within* an increment.

   The task list and `04-roadmap.md` are not substitutes for each other, and it is easy to end up feeding only the first. The task list is scratch: it tracks this session's steps and dies with the conversation. The roadmap is the durable ledger, and it is what a future session or a new collaborator reads. Whenever the two disagree about where the work stands, the roadmap is the one that is wrong and the one that must be fixed — a perfectly maintained task list beside a roadmap that still says "not started" is the same failure as no record at all.
7. **Verify it.** Run it, or say plainly that you did not. Never report an increment as done on the strength of the code looking right.
8. **Update the docs** — see below.
9. **Report and pause.** What landed, what you verified, what is next.

Do not chain increments without stopping. The pause between them is where the user catches a plan that has stopped matching reality — which is cheap here and expensive three increments later.

## Keeping documents true

Code drifting from documentation is the failure that undoes everything the first four phases built. After every increment:

- `04-roadmap.md` — mark the increment done, with a one-line note on what actually shipped if it differs from the plan.
- `00-state.md` — current position, what is next, any newly discovered unknown.
- `02-decisions.md` — implementation nearly always forces decisions that planning did not anticipate. Record them in place, in the same format. A choice made while writing code is exactly as binding on the next person as one made in Phase 3.

  The test for whether something belongs here is not how large it felt while solving it. Ask instead: **does this constrain what a future developer may do, and would they know it from the code alone?** A deliberate exception to a rule the project otherwise enforces, a workaround with a boundary that must not be widened, a mechanism chosen over an obvious alternative for a non-obvious reason — all of these qualify, and all of them get skipped, because at the moment of solving they feel like implementation detail rather than decision.

  A comment in the code is not sufficient for these. Comments are found by people already reading that file; a decision that constrains the whole project has to be findable by someone who does not yet know which file to open. Write it in `02-decisions.md` before the increment closes, and reference it from the code if it helps.
- `CLAUDE.md` — only when a convention or rule genuinely changed. Not a changelog.

### Reversing a decision

When a decision made in an earlier phase is overturned, writing the new decision is the easy half. The hard half — and the one that gets skipped — is **sweeping everything the old decision had already been written into.**

Adding a paragraph that states the new truth does not remove the old one — see the reversal rule in `SKILL.md` for why the stale half is the dangerous one.

After recording a reversal, search the documents for every statement that encoded the old choice and rewrite or delete each one. Grep for the rejected technology's name, but also for the *shapes* the old decision implied — a shared layer that no longer exists, a file that will not be created, a constraint that no longer binds. `CLAUDE.md` rules and `04-roadmap.md` increments are where these hide, because they were written as consequences rather than as decisions.

Then state plainly which documents you changed. A reversal that touches one file is usually a reversal that was swept incompletely.

If an increment invalidates something planned — the chosen library does not do what the research claimed, the data model does not survive contact with the real flow — stop and say so. Rewrite the affected decision and the remaining roadmap with the user, then continue. Working around a broken plan silently is how a project ends up with documents nobody trusts, at which point the whole apparatus is dead weight.

## Scope discipline

Build the increment as specified. Adjacent improvements that occur to you along the way — refactors, extra error handling, a nicer abstraction — go into the "Later" section of `03-mvp.md`, not into the current change. The user decides what gets built; the roadmap is the agreement.

Two exceptions: something actually broken that blocks the increment, and something that makes the increment's own code wrong. Fix those and say that you did.

## When the MVP is done

When the last increment lands:

1. Verify against the success criterion in `01-brief.md` — the measurable sentence from Phase 1. State plainly whether it is met. If it is not, say what is missing rather than declaring victory.
2. **Write the README** — from `templates/README-internal.md` or `templates/README-public.md`,
   whichever the publication decision in `02-decisions.md` calls for.

   It is written now rather than at scaffolding time because until this point there was nothing to
   document — a README describing intentions is a promise, and promises age badly in a file people
   read as fact. `CLAUDE.md` has been orienting anyone who opened the repository in the meantime.

   The two shapes have genuinely different jobs. **Internal**: what it is, how to run it, where the
   documents are — its reader already knows why the project exists. **Public**: the problem before
   the solution, real output early, honest limitations — its reader is deciding in thirty seconds
   whether to keep reading, and knows nothing.

   Do not write a public README for an internal project. The badges, the contributing section and
   the elaborate feature list are costume, and they make a working tool look like an abandoned
   product.
3. Update `00-state.md` to "MVP complete", listing what shipped and what was deferred.
4. Review the remaining assumptions — the ones never forced by any increment are now known unknowns for whoever continues.
5. Move surviving "Later" items into a shape the next session can pick up.

The project does not leave this tool at that point. A new feature re-enters at Phase 1 for a scoped round of questions, or at Phase 3 if the questions are already answered. `/project` reads `00-state.md` and routes accordingly — which is the whole reason that file exists.
