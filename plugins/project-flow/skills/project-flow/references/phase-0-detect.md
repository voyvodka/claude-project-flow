# Phase 0 — Detect

Goal: figure out what this folder already is, and tell the user where they stand. Costs seconds, prevents every kind of duplicated or contradictory work later.

`SKILL.md` runs this phase whenever `docs/product/00-state.md` is missing, and it is never skipped then — even when the user opens with a clear new idea. A folder that looks empty may hold a `.git` history, a half-written brief, or someone else's abandoned attempt.

## Scan

Look at, in this order:

1. `docs/product/00-state.md` — if present, this is a resumption. It is authoritative.
2. `docs/product/` and `docs/research/` — which documents exist, how complete are they.
3. `CLAUDE.md`, `AGENTS.md`, `README.md` — is there already a stated project identity.
4. Manifests: `package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `*.csproj`, `composer.json`, `Gemfile`.
5. Source layout — enough to name the stack and rough size, not to understand the code.
6. `git log --oneline -15` and `git status --short` if it is a repo — recent activity says more than file counts.

Read the product docs in full; they are short and they are the memory. Sample the code, do not read all of it.

## Classify

Pick exactly one:

| Class | Signals | Enter at |
|---|---|---|
| **Empty** | No source, no docs, at most a `.git` or a README stub | Phase 1 |
| **Resumption** | `00-state.md` exists — `SKILL.md` normally routes this before Phase 0 loads | The phase it names |
| **Closed** | `Aktif faz` says the MVP or a round is complete, or reads `Bakım` | Re-entry, below — never Phase 5 by default |
| **Docs without state** | Product docs exist but no `00-state.md` — an older run, or hand-written notes | Reconstruct `00-state.md` from what is there, then continue |
| **Existing code** | Real source, no product docs — a project started outside this tool | Phase 1, seeded from the code |
| **Foreign** | Someone else's repo, or clearly unrelated to a new project | Stop. Ask what the user actually wants |

## Report

Give the user a short, concrete read — never a wall of findings:

- What this folder is, in one sentence.
- What is already settled (from docs or from code).
- What is missing or stale.
- The single next step, with the phase named.

Example shape:

> Klasörde 01-brief ve market araştırması var, karar dosyası boş. Stack seçilmemiş. Sıradaki adım Faz 2 — teknoloji araştırması. Başlayalım mı?

Then wait for approval.

## Reconstructing state — only after the report is approved, never before

For "docs without state" and "existing code", write `docs/product/00-state.md` from the `templates/00-state.md` skeleton before doing anything else, filling only what the evidence supports.

Two rules while reconstructing:

- Anything inferred from code rather than confirmed by the user is written as `⚠️ VARSAYIM` (or `⚠️ ASSUMPTION` in an English-language project), never as a settled fact. Inferring the stack from `package.json` is safe; inferring *why* that stack was chosen is not.
- Do not modify existing product docs during Phase 0. Detect, record, and report. Corrections happen in the phase that owns those documents, with the user present.

## Existing code

When there is real source but no product docs, the checklist in Phase 1 still applies — but several items can be seeded from evidence, and those become the *first* questions rather than blanks:

- Stack, dependencies, deployment target → read from manifests and config.
- Main flow → inferred from routes, entry points, or CLI commands.
- Scale, auth model, integrations → read from config, middleware, and external clients.

Present these as "here is what I read from the code, correct me" rather than as open questions. It is faster for the user and it surfaces drift between what the code does and what they believe it does — which is frequently the most valuable output of the whole phase.

**The mirror of that list is the dangerous half.** Code reports what was built and is silent on whether its author thinks it is any good, so none of this can be seeded and all of it must be asked:

- Whether they consider the product fit to show anyone yet, and what specifically is missing if not.
- Which shipped features they consider *finished* rather than merely present.
- What they want it to become — the quality bar, not the feature list.

A working codebase is persuasive. It reads as settled, its decisions look deliberate, and its author's dissatisfaction with it appears in no file. A phase that seeds everything readable and asks nothing else will order the whole project against goals its owner would not have chosen.

## Re-entry — after the MVP

A closed project still gets new work, and without a route that work lands as increment after
increment appended to a finished roadmap, with no question asked and no research done. This
section is the route. It runs whenever `/project` finds the project closed.

1. **Check the record against the code.** Compare `git log` since the state file's last update with
   `04-roadmap.md`. Work that shipped without an increment, an MVP-close step left undone (the
   success-criterion verdict, the README), a decision made in code and never written down — report
   each one. They are fixed before new work starts, because the new work will be planned on top of
   them.
2. **Bring the documents to the current shape** — once per project, the first time it re-enters
   after the templates changed. Dated sections in `00-state.md` go to `archive/state-log.md`, the
   header fields go back to one line each, and a decision record past ~800 lines is split by topic
   (the `02-decisions.md` template says how). This is the one exception to Phase 0 leaving the
   documents alone: propose the moves, make them on approval, and delete nothing.
3. **Ask what the new work is**, then name one of three modes and wait for the go-ahead:

| Mode | When | What happens |
|---|---|---|
| **Increment** | It traces to an item in `03-mvp.md › Sonrası`, or fixes shipped behaviour, and it fits in one or two increments | Added to `04-roadmap.md`; Phase 5 resumes for it, and `Aktif faz` returns to its closed state when it lands |
| **Round** | New capability, a changed goal, or anything that does not trace back — and always once two increments have been added since the last close | A numbered round runs the phases again, scoped to the new work |
| **Maintenance** | No new capability; the project is kept working | `Aktif faz: Bakım`; `Sıradaki adım` names the next review date or the open defects |

**A round** is the same process, sized to the change rather than to a new project:

- Phase 1 asks only what the new work touches — its problem, its flow, its own success criterion,
  what is out of scope for it. The MVP's out-of-scope list was the scope of one release, not a
  standing principle; it does not carry over unless the user says it does.
- Phase 2 runs only for a question the user cannot answer and the code does not settle. Phase 4
  runs only if the tooling has to change.
- Phase 3 records the round's decisions in the usual place and writes a `## Tur N` section in
  `03-mvp.md`. The closed round's part of `04-roadmap.md` moves to `archive/roadmap-<round>.md`,
  leaving one line that points at it, so the ledger shows only work that is still open.
- Every phase row it reruns is added to the phase history as "(tur N)", and `Aktif faz` carries the
  round: "3 Netleştirme — tur 2 (onay bekliyor)".
- It closes like the MVP did (`phase-5-build.md`): a verdict against the round's own success
  criterion, then `Aktif faz` reads "5 Uygulama — tur N (tur tamamlandı)" and the next
  `/project` lands here again.
- A standing approval the user gave for one round expires with it.

