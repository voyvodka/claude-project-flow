# Phase 2 — Research

Goal: replace opinion with evidence on the questions that are expensive to get wrong. This phase writes `docs/research/`.

Research runs in **subagents**, not in the main conversation. Each branch digs deep in its own context, writes its findings straight to its own file, and returns only a short summary. This is what keeps a single long chat viable: the main conversation ends the phase holding three summaries, not three hundred search results.

## Branches

| Branch | File | Answers |
|---|---|---|
| Market | `docs/research/market.md` | Who else solves this, how, at what price, what they are bad at |
| Tech | `docs/research/tech.md` | Which stack, which libraries, what the real trade-offs are |
| Dev environment | `docs/research/devenv.md` | How it is developed, tested, deployed, and operated |

Run the branches **in parallel** — one `Agent` call per branch, all in a single message.

## Which branches to run

Do not run all three reflexively.

- **Market** — skip for personal tools, internal tools, and anything with no competitive dimension. Say you are skipping it and why.
- **Tech** — skip if the user has already committed to a stack. Record it as a user-supplied decision instead. Still worth running for the *libraries within* a fixed stack.
- **Dev environment** — almost always worth running, and the one most often forgotten. It is where deployment surprises come from.

If a project raises a genuinely separate question — a regulatory constraint, a specific integration's feasibility, a hard performance target — add a fourth branch for it. Give it its own file under `docs/research/`.

## Subagent prompts

Use `subagent_type: "general-purpose"`. Give each branch the brief, not a summary of the brief — paste the relevant parts of `01-brief.md` into the prompt. A subagent cannot see this conversation.

Every branch prompt must carry these instructions:

```
Write your findings directly to <target file>. Use the same language as docs/product/01-brief.md.

Structure — the file opens with a section numbered 0, titled "dead ends" in the
document's language, before anything else. It holds the findings that change a
decision: walls, disqualifiers, reasons NOT to do something. A reader who stops
after section 0 must still get everything that would change their mind. Detail
sections follow it, then sources.

Rules:
- Every factual claim needs a source (URL, or the doc tool you used).
- Mark verification status inline, next to the claim it belongs to — a tick when
  you confirmed it against a primary source, a warning marker when you did not,
  with one clause saying why (single blog-level source, figure not found in the
  official text, and so on). Do not collect these into a section at the end: the
  marker has to travel with the claim, because the claim gets quoted later without
  the rest of the file.
- Anything you cannot source at all, say so plainly. Never present it as fact.
- When a primary source disagrees with secondary write-ups, report both and say
  which is which. That gap is itself a finding.
- In any calculation, separate what you verified from what you assumed. State the
  split explicitly: which inputs are sourced prices or published limits, and which
  are your own usage estimates.
- Library and framework docs: use Context7 (resolve-library-id, then query-docs).
  Your training data on versions and APIs is stale. Do not answer from memory.
- Report trade-offs, not a winner. The user decides in the next phase.

Return to the caller: at most 10 lines. The 3 findings that change a decision,
and any question the user now has to answer. Nothing else — the file holds the detail.
```

Branch-specific additions:

- **Market** — name real competitors with links, their pricing tier, and the specific gap the user's idea targets. If the space is crowded, say so bluntly; that is a finding, not a failure. Note if you find *no* competitors — that usually means the market is small, not untapped.
- **Tech** — paste the constraints from `01-brief.md` (team size, deadline, existing skill) and the **whole of the relevant `profile/` stack file** plus `profile/avoid.md` and `profile/infrastructure.md` into the prompt, then frame the question as **"is there a reason to deviate from the default for this project?"** rather than "which stack should we use?". The branch must either defend the default or name the specific requirement that breaks it — a candidate is only worth proposing if it beats the default on something this project actually needs. If the profile has no default for this project type, or the project overrode it in Phase 1, fall back to 2–3 candidates with an honest case for each. Either way: weigh the maintenance and hiring dimension, not just the technical one, and check current major versions via Context7.

  > ⚠️ **`profile/infrastructure.md` is usually the local override, and the local override is private.**
  > `profile/local/infrastructure.md` is gitignored precisely because it holds real hostnames,
  > provider and account names, port lists, domain portfolios, backup schedules and the split between
  > personal and workplace machines. This branch writes into `docs/research/tech.md`, which is a file
  > this tool tells the user to **commit** — in a different repository from the one the profile
  > describes.
  >
  > So: pass it in for **judgement**, never for **transcription**. The branch may conclude "a managed
  > Postgres has to clear a cost bar because a paid-for server already exists" or "the target host has
  > limited headroom, so rule out anything that needs its own runtime". It must never copy a hostname,
  > IP, port, provider name, account name, domain, price or credential into the research file, or into
  > its returned summary. If a finding cannot be stated without one of those, state the constraint in
  > the abstract and say the detail is in the local profile.
  >
  > The committed `profile/infrastructure.md` already applies this rule to itself — *"Never write
  > network addresses into this file… This file is likely to be shared."* The research output is
  > shared the same way and gets the same rule.

  **When the profile says an AI writes most of the code, that is a first-class selection criterion, not a footnote.** The branch must weigh, for each candidate:
  - How well represented the stack is in model training data, and how stable its APIs have been. A framework that rewrote its core idioms recently produces confidently wrong code, because the model has learned both the old and the new shape.
  - How verifiable the output is without running it — static types, a compiler, a fast test path. This is what converts AI speed into AI reliability; a stack where mistakes surface only at runtime gives back everything it saved.
  - **Whether the agent can close the loop itself: run the thing, observe what it did, and confirm the result with no human in the middle.** This is a separate question from writing good code, and it is often the one that decides. A web interface an agent can drive in a browser and screenshot is in a different category from a mobile app that needs a simulator, a device, or a person tapping. Research the actual tooling — headless runners, e2e drivers, simulator automation, screenshot feedback — and report honestly where the loop still needs a human. Where a target platform closes the loop badly, say what the alternatives are: a different framework, a different test harness, or a different delivery form for that surface entirely (a responsive web view instead of a native app, when the reason for going native was perception rather than capability).
  - Whether current documentation is reachable through Context7, so the model can check itself instead of recalling.
  - How readable the result stays for the human who still has to review, debug, and operate it. Delegating authorship does not delegate responsibility, and an unfamiliar stack costs the reviewer even when it costs the writer nothing.

  These can point away from what the human knows best. Say so when they do — that tension is the finding, and the user resolves it in Phase 3.
- **Dev environment** — local setup, testing approach, CI, deployment target, environments, secrets handling, monitoring, and rough running cost. Weight it toward what a one-to-three person team can actually operate.

## Handling the results

**Write which branches were launched into `00-state.md` the moment they are dispatched**, before any
of them returns — the same rule Phase 5 applies to increments. A branch writes straight to its final
file in `docs/research/`, so a session that dies mid-fan-out leaves a file on disk that Phase 0 will
read as finished work. Recording the launch is what lets the next session tell "this branch
completed" from "this branch was interrupted while writing". Mark each one done as it returns, not
all of them at the end.

When the branches return:

1. Read each branch's summary. **The research file is the deliverable; the returned summary is only a
   convenience.** If a branch's summary does not arrive, read its file directly — a missing return
   value is not a failed branch, and the work is already on disk. Otherwise do not re-read full files
   unless something is unclear or contradictory.
2. Reconcile conflicts across branches out loud, in their own section. A stack the tech branch loves that the devenv branch cannot deploy cheaply, a feature the market branch calls a sellable premium that the platform rules forbid — these are the findings no single branch could produce, and they are the reason for running branches in parallel rather than one deep pass. For each conflict, state both sides and whether a resolution exists.
3. When a branch contradicts something you told the user earlier — including a hypothesis you offered while framing the research — lead the summary with the correction, plainly. Do not quietly drop it and move on. The user reasoned with what you said; they are entitled to know it did not hold. Name the faulty step, not just the wrong conclusion — "one tool's limitation was generalised to the whole platform" tells the reader which other claims to distrust; "that was wrong" does not, and lets the same inference recur. Equally: when a user's objection was well-founded but the evidence did not change the answer, say both halves. Validating a question is not the same as reversing a conclusion, and merging the two to sound agreeable is how a research phase stops being worth running.
4. Present the summaries to the user together, with the open questions each one raises. Lead with whatever most undermines the plan as written, including the user's own stated premise — especially that. A research phase that confirms everything found nothing.
5. Size the summary to the project. Every paragraph should carry a decision the user now has to make; if one does not, it belongs in the file, not the summary.
6. Update `00-state.md`: which branches ran, which were skipped and why, which questions are now on the table.

Do not make the decisions here. Presenting findings and choosing between them are separate steps, and mixing them is how research turns into rationalization for what you already preferred.

## Gate

The phase ends with research files written, summaries delivered, and a clear question: ready to lock these into decisions?

Wait for approval before Phase 3.
