# State

> The single source of where this project stands. The first file to read when handing over to a
> new conversation or a new person. Updated at the end of every phase.
>
> **Describes the present only, rewritten in place.** No dated headings; what happened lives in git
> and in `archive/state-log.md`. Limit: ~120 lines, ~10 KB, at most ~10 open items. Past that, the
> oldest part moves to the archive — trimming is not enough, a trimmed file grows back.
> Assumptions and the phase history sit outside this limit.

**Last updated:** <DATE>
**Active phase:** <0 Detect | 1 Discover | 2 Research | 3 Decide | 4 Scaffold | 5 Build | Maintenance>
<One line. Follow the phase number with its status in parentheses — "5 Build (awaiting approval)",
"2 Research (interrupted)", "5 Build (MVP complete)". In a round after the MVP, add the round:
"1 Discover — round 2 (in progress)", "5 Build — round 2 (round complete)". The phase number says
where we are, the parentheses say whether that phase is finished; without both, an interrupted
phase looks complete. The position lives on this line only — never open a second position line.>
**Next step:** <one sentence, at most ~300 characters — the first thing the next conversation does.
In Phase 5 this line **points at** the increment rather than describing it: "Increment 3 ·
`04-roadmap.md`". The content lives there; kept in two places, one goes stale.>
**Document layout:** <full (five files) | compact — decisions `01-brief.md › Decisions`, roadmap `03-mvp.md › Roadmap`>
<In compact, the line carries this mapping as written: phases after Phase 1 do not read the file
that defines the mapping, and learn it from this line.>

## The project in one sentence

<What we are building, and for whom.>

## Settled

| Topic | Status | Where |
|---|---|---|
| <topic> | <decision> | `docs/product/02-decisions.md` |

## Open

- [ ] <unanswered question — whose answer it waits on. A closed item is deleted: a decision moves
  to `02-decisions.md`, work moves to `04-roadmap.md`.>

## Assumptions

> Never deleted. When implementation touches something resting on an assumption, ask the user.

| ID | Assumption | Why it was assumed | What breaks if it is wrong |
|---|---|---|---|
| A1 | <assumption> | <reason> | <impact> |

## Phase history

> Process notes for each phase go in the "Note" column: research branches launched and finished,
> the merge / replace / write-beside choice for an existing `CLAUDE.md`, tooling built on request
> rather than on recommendation. No new headings.

| Phase | Status | Note |
|---|---|---|
| 0 Detect | <done / skipped / waiting> | <if skipped, why> |
| 1 Discover | | |
| 2 Research | | |
| 3 Decide | | |
| 4 Scaffold | | |
| 5 Build | | |

<Each round opened after the MVP continues with rows marked "(round 2)" for the phases it reruns.>
