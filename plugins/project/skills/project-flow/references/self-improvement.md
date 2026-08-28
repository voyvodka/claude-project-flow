# Self-Improvement

This tool is a set of written instructions, and written instructions fail in ways only real use
reveals. Projects run through it are the only evidence that exists about whether it works.

The purpose of this file is to make that evidence usable **without turning every irritation into
a new rule.** A tool that grows a rule for every miss ends up too long to read, and an unread
instruction is worse than a missing one — it looks like coverage.

## The distinction that matters

**A defect in the project is normal work.** A bug in the code, a wrong decision, a missing test:
fix it, record it, move on. That is what the phases are for and it says nothing about the tool.

**A defect in the tool is when the tool's own instructions produced the bad outcome.** The
question to ask is narrow:

> Did I follow the instructions and still get a bad result — or would following them have
> prevented this?

If the instructions were followed and the outcome was still wrong, that is a tool defect. If the
instructions would have prevented it and were not followed, ask *why not* — an instruction that
is routinely skipped is usually buried, ambiguous, or placed where nobody looks, and that is a
tool defect too.

## When to look

At phase gates and at increment close — the moments where a phase's work is already being
summarised. Not continuously. Reviewing the tool mid-task is a distraction from the task, and the
evidence is clearer once a phase has finished anyway.

One question, asked once: **did anything here go wrong because of how this tool is written?**
Usually the answer is no, and that is the end of it.

## Failure classes

Real ones, worth recognising:

| Class | Looks like |
|---|---|
| **Only works on success** | A record written when a step completes, so a step that dies mid-way leaves no trace — exactly when the record was needed |
| **Dangling reference** | An instruction weighing information that nothing ever collects |
| **Too blunt** | A rule correct in general that produces the wrong answer in a case it never anticipated |
| **Duplication** | Two places describing one fact, so one goes stale and a reader follows the wrong one |
| **Never fires** | A rule that is present, correct, and consistently skipped — buried, vague, or in the wrong file |
| **Noise** | A rule that fires as intended and produces output nobody uses |

## The bar for changing the tool

**One project is one data point.** Separate two kinds of finding:

- **Structural** — the failure follows from how the instruction is built, and would recur in any
  project. A record only written on success will fail every time a run is interrupted. A dangling
  reference is dangling for everyone. **Fix these immediately**, and say so.
- **Circumstantial** — it happened once and might be this project's particularity. Perhaps this
  domain is unusual, perhaps the phrasing was unlucky. **Log it, do not edit.** If the same
  observation appears in a second project, it has stopped being circumstantial.

When unsure which it is, log it. An unlogged observation is lost; a logged one costs a line.

## How to fix

**Remove the cause before adding a reminder.** If a rule tells the reader to update two files and
one keeps going stale, the answer is usually to stop keeping the fact in two places — not to
repeat the instruction more firmly. "Remember to X" is the weakest possible fix and it accumulates.

Prefer, in order:

1. **Remove the need.** Restructure so the failure cannot happen.
2. **Change the shape.** A blank row in a fixed table is visible; a missing paragraph is not. Make
   the gap physically obvious rather than relying on attention.
3. **Sharpen the existing rule.** Say the same thing where it will actually be read.
4. **Add a rule.** Last resort, and it carries the reason with it — a rule whose *why* is written
   down survives the next person who thinks it is redundant.

**Then watch it fire.** A change is applied when its rule has been seen to work, not when the text
is saved. Where the trigger can be reached deliberately, reach it; where it cannot, say that the
fix is untested. Rules added without watching them fire are assumptions, and one has already
shipped correct, prominent and unable to fire.

## Never edit silently

The tool applies to every future project. A change justified by one project's experience can
degrade every other one, and the author of the change is the least able to see that.

So: **propose, do not apply.** State what happened, which class it falls into, what the change
would be, and what it might cost elsewhere. The user decides. This holds even when the fix looks
obvious — especially then, since obvious fixes are the ones that get made without checking.

Two exceptions, both narrow: fixing a factually broken reference (a path that does not exist, a
file name that changed), and correcting an internal inconsistency where one of two contradictory
statements is plainly stale. Both are repairs, not design changes.

## Where the edit has to land

**Check first whether this plugin is running from a copy that survives an update.** A marketplace
install is copied into a versioned plugin cache; an edit made there is deleted the next time the
plugin updates, and it is deleted silently — the proposal was accepted, the file was written, and
the change is simply gone. That is the same failure `profile/README.md` describes for
`profile/local/`, and it applies to every file in this skill, not just that directory.

So before applying anything: if `${CLAUDE_PLUGIN_ROOT}` points inside a `plugins/cache/` path, say
so and stop. The change belongs in the source repository — open it there, or hand the user the
proposal to carry over. An accepted change that cannot survive an update is worse than a rejected
one, because everyone involved believes it landed.

## Logging

Append to `feedback/observations.md` next to this skill. One entry:

```
## <short title>
- **Project:** <where it was seen>
- **Class:** structural | circumstantial
- **What happened:** <one or two sentences — the outcome, not the feeling>
- **Instruction involved:** <file and rule, or "none — gap">
- **Proposed change:** <or "none yet — needs a second sighting">
- **Status:** logged | proposed | applied in vX.Y.Z | rejected
```

Keep the log short the same way the project-level gotchas ledger is kept short. Entries that were
applied can collapse to a line once the change is in; entries rejected stay, with the reason,
because the same idea comes back.

## What not to do

- Do not fix the project by changing the tool. If this project needs different behaviour, that is
  a project decision, recorded in `02-decisions.md`.
- Do not log preferences. "I would have phrased this differently" is not evidence.
- Do not rewrite a rule that worked because a *better* rule occurred to you. Improvement without
  evidence is how a working tool acquires untested behaviour.
- Do not treat the user overruling the tool as a defect. Often it is just their call to make. The
  test for when it is a defect is narrow: **the tool's own stated criteria were already met and it
  under-applied them.** Disagreement about a judgement the tool was entitled to make is not a
  defect; failing to apply a rule the tool already carried is.
