# Phase 3 — Decide

Goal: convert findings into decisions the user actually owns. This phase writes `docs/product/02-decisions.md` and `docs/product/03-mvp.md`.

Research produces options. This phase produces commitments. The distinction matters because a commitment is something the next person — or the next session — can build on without relitigating it.

## Walking the decisions

Go through the open questions **one topic at a time**, not all at once. For each:

1. State the options, briefly, with the trade-off that actually separates them.
2. Give a recommendation. Not a survey — a recommendation, with the reason in one sentence.
3. Let the user choose. `AskUserQuestion` with concrete options works well here; the answer space is genuinely bounded at this point.
4. Write the decision into `02-decisions.md` immediately.

Recommend rather than enumerate. The user asked for help deciding, not for a menu. But recommend honestly: if the research came back genuinely ambiguous, say that the choice is close and name the tiebreaker.

### When research cannot settle it — measure

Sometimes a decision turns on one fact no amount of reading will confirm: whether a tool actually works as documented, whether a library handles the project's real shape, whether an approach is fast enough. Documentation says it should; nobody has written down whether it does.

Do not guess, and do not push the user to guess. Propose a **spike**: a timeboxed experiment, usually under an hour, that answers exactly one question. State four things — the question, the timebox, what counts as pass and fail, and **what each outcome decides**. A spike whose result would not change the decision is not worth running.

Two rules keep spikes from becoming a way of avoiding decisions. Only one question per spike, and only when the answer genuinely flips the choice — everything else is decided with the evidence already in hand. And spike code is thrown away; it is a measurement, not a head start on the increment.

When a spike concerns tooling or workflow rather than the product, be precise about which loop it affects. "Can this be tested at all" and "can it be tested without a human in the loop on every change" are different questions with different stakes, and the second one is usually the real one.

## Decision format

Decisions are updated **in place** — no separate ADR file, no superseded history. Git holds the history.

Each entry carries what a stranger needs to not undo it by accident:

```
## <Topic>

**Karar:** <what was chosen>
**Neden:** <one or two sentences — the reason that actually decided it>
**Elenenler:** <what was rejected, and the specific reason>
**Kabul edilen bedel:** <what this gives up — "—" if genuinely nothing>
**Bağlı olduğu varsayım:** <assumption ID, if this decision rests on one>
```

**The labels are written in the document's own language, not copied from here.** The block above is
shown in Turkish because that is this profile's default; `02-decisions.md` follows the user's
language like every other product document, so in an English-language project the same five fields
are `Decision` / `Why` / `Rejected` / `Accepted cost` / `Rests on`. What is fixed is the *five
fields* — every entry carries all five, whatever they are called. The same goes for the literal
values used below: `yok` is `none` in an English document.

When a stack decision **departs from the profile default**, say so explicitly in the **Neden**
line — "varsayılan X'ti, <şu gereksinim> nedeniyle Y seçildi". A deviation carries a real cost
in ramp-up time, so the reason has to survive being read back later. When the default is kept,
one line is enough; that is the point of having a default.

The "Elenenler" line is the one that earns its keep on handover. Without it the next person re-evaluates the same rejected option and reaches the same conclusion, slowly. It is never left blank: if there genuinely was no alternative, write "yok" and the reason. An alternative folded into the **Neden** sentence does not count — it has to be findable where a reader looks for it.

**Kabul edilen bedel** matters just as much and is easier to skip. Most real decisions give something up: offline access, a segment, a integration, a performance ceiling. Naming it tells the next reader the downside was seen and chosen, not missed — which is the difference between them trusting the decision and reopening it. When a decision costs nothing, write "—" rather than leaving the line off.

When a decision changes later, rewrite the entry in place and note the reversal in the **Neden** line — "önce X seçilmişti, Y nedeniyle değişti". The point is that the current file always reads as current truth.

## Will this be published?

Decide it here, and record it. It looks like a question for later and is not: **once a repository
is public, its history is public too**, and everything below is expensive to undo afterwards.

What it settles now rather than later:

- **Licence** — chosen before the first commit, not bolted on. Contributors and users need it to
  exist from the start.
- **Secrets and internal references** — a private repository tolerates a hostname, an internal IP,
  a customer name in a comment. A public one does not, and removing them later means rewriting
  history.
- **Commit identity** — see `profile/local-environment.md`. An address that is fine internally may
  be wrong to publish under.
- **Dependency licences** — only worth checking when redistribution is on the table.
- **Which documents ship** — `docs/product/` holds internal reasoning and may be in the working
  language rather than English.

"Undecided" is an acceptable answer, and it has a consequence worth stating: **build as though it
will be published.** Keeping secrets out and identity correct costs nothing while private and is
the whole cost afterwards.

## Repository layout

Decide it here, with the stack, and record it as a decision. `profile/repo-layout.md` carries the
rule and its trigger.

It belongs in this phase because it is built in the first increment and is expensive afterwards —
a layout change two increments in touches every import, every CI path, and every path written into
`CLAUDE.md` and the documents.

## MVP scope

Once the technical and product decisions are settled, write `03-mvp.md`:

- **Included** — the smallest set that satisfies the success criterion from `01-brief.md`. Trace each item back to that criterion; anything that does not trace is not MVP.
- **Excluded** — carried forward from item 5 of the discovery checklist, plus anything cut during this phase, each with its reason.
- **Later** — real ideas parked for after MVP. Having this list is what makes cutting scope tolerable.

Push back on scope here, once, concretely. Naming the two features that would most delay a first working version is more useful than a general warning about scope creep. If the user keeps them, that is their call — record it and move on.

## Roadmap

Write `04-roadmap.md`: the MVP broken into increments that each end at something demonstrable.

- Each increment: a name, what it delivers, what it depends on, and how you will know it works.
- Order by dependency and by risk. The increment most likely to invalidate the plan goes early, while changing course is still cheap.
- Keep it to a size that matches the project. Four increments for a small tool is right; twenty is a symptom.

This file is also the progress ledger — Phase 5 checks items off here.

## Assumptions

Re-read the assumption list in `00-state.md` before closing the phase. Research often answers one silently. For each:

- **Confirmed by research** — promote it to a decision, remove the marker, note the source.
- **Settled by another decision made in this phase** — promote it too. This is the one that gets missed: choosing a positioning or an architecture often answers a standing assumption as a side effect, and nobody goes back to clear it. After writing the last decision, re-read the assumption list once more and ask of each: is this still genuinely open, or did something above just decide it?
- **Contradicted** — raise it with the user now. An assumption that research disproved is the cheapest bug this project will ever have.
- **Still open** — keep it marked, and note which increment in `04-roadmap.md` will force the question.

## Check the set against itself

Before the gate, read the decisions **as a set** rather than one at a time. They were written
individually, over hours, and nothing so far has asked whether they agree with each other.

Two checks, both mechanical:

1. **Does any decision contradict another?** Two entries can each be reasonable and jointly
   impossible. This is easy to miss because the second one is written long after the first has
   stopped being in mind.
2. **Does any planned increment violate a constraint the project has already accepted?** Walk each
   roadmap item against the out-of-scope list and the stated rules, and ask what it will actually
   *do* — not what it is for. A feature described by its purpose sounds compatible; described by
   its mechanism it often is not.

The second check is the one that catches real problems, and it needs the mechanism spelled out. A
feature that "checks whether a repository is behind" sounds harmless next to a rule saying the tool
never modifies a repository — until you note that the obvious implementation writes to it.

Where a contradiction turns up, resolve it here. Carrying it into implementation means discovering
it with code already written against the losing side, and the cost is not the code — it is that by
then the contradiction has usually been built on.

Summarize the plan in a handful of lines — stack, MVP shape, first increment — and ask whether to proceed to scaffolding. Wait.
