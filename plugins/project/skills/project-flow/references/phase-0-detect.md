# Phase 0 — Detect

Goal: figure out what this folder already is, and tell the user where they stand. Costs seconds, prevents every kind of duplicated or contradictory work later.

Never skip this phase, even when the user opens with a clear new idea. A folder that looks empty may hold a `.git` history, a half-written brief, or someone else's abandoned attempt.

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
| **Resumption** | `00-state.md` exists | The phase it names |
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

## Reconstructing state

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
