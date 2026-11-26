# Defect Report

When this tool's own instructions produced a bad outcome (`self-improvement.md` › The distinction
that matters), the fix belongs in the tool's source repository, not in this install: an install's
files are replaced on the next update. This file turns such a finding into a prefilled issue link
that the user opens and submits on GitHub themselves, while the user keeps working, and with
nothing personal in its text. Sending a fix as a pull request is not part of this release.

The report script is the path named in `SKILL.md` › Routing; this file calls it `report.sh`. Run it
with `bash`.

## What the user sees

Two yes/no questions, nothing else:

1. **Whether to prepare a report.** At a phase gate or increment close, or in the reply to the
   user's own complaint about the tool — never in the middle of a task. Ask one line, in the user's
   language: *This looks like a defect in project-flow itself: <one abstract line>. Shall I write it
   up in the background as a prefilled issue link that you can check and submit yourself? You will
   see its exact text first.* If the user asks for a pull request, say that this release offers
   only the issue link.

   Ask it once per finding. A no ends it: nothing is written or kept.
2. **Whether to make the link from exactly the preview.** Asked once the background work is ready
   (below).

## After the first yes

Start a `general-purpose` agent with the Agent tool, `model: "sonnet"`, `run_in_background: true`,
with the brief below filled in. Then carry on with the user's work; say in one line that the report
is being prepared. The brief carries the finding only in abstract terms — no quotes, no project or
person names — because the agent writes the text that leaves.

```
You write up one defect in the project-flow plugin's own instructions as an issue, using a fresh
clone of its source repository to check it, and leave a report payload for the user to preview.
You send nothing and change nothing: the clone cannot push, and the issue link is made later in the
main session after the user approves.

Defect — class: <...>; instruction involved: <...>; what happened: <...>; proposed change: <...>
Report script: <report.sh path>. Project directory (scrub input only): <path>
Do not read, list or quote anything inside the project directory.

1. `bash <report.sh> clone` prints a workdir W; the plugin is at W/src/plugins/project-flow/.
2. If the source already fixes it (the install may be older), stop: status "already fixed", with
   file and line.
3. Work out the smallest change that would remove the cause (W/src/plugins/project-flow/skills/
   project-flow/references/self-improvement.md, How to fix) and describe it in proposed-change. Do
   not edit any file in W/src.
4. Write W/fields: exactly five lines, English, abstract, no quotes, names or outside paths:
   title: <imperative, at most 80 characters>
   class: <failure class>
   instruction: <plugin file and rule>
   what-happened: <general terms, at most 500 characters>
   proposed-change: <what the fix would change and why, at most 500 characters>
5. `bash <report.sh> prepare --workdir W --project <project dir>`. On BLOCKED, rewrite the named
   text in more general terms and rerun; never work around a finding. Stop after three blocks.

Reply with three lines: workdir: W / status: prepared|blocked|already fixed / one sentence on the
proposed change. Never run preview or send; never push, fork or open anything on GitHub.
```

## When the agent finishes

At the end of the next reply — not in the middle of the user's task:

- **prepared** — run `report.sh preview --workdir W --project <project dir>` and paste its output
  **verbatim** in a code block: every line between the BEGIN and END markers and the `Digest:` line.
  Do not summarise, shorten or reformat it. Then ask: *Make the issue link from exactly this?* **End
  the reply there.**
- **blocked** — say which kinds of finding blocked it (home path, e-mail address, user or machine
  name, project name or file name) and that nothing was sent. Offer to
  retry with a more general description; a retry is a new first question.
- **already fixed** — say so with the file, and suggest updating the plugin.

## After the second answer

Only a message the user sends after seeing the preview counts. An approval given earlier — "send
it", "you don't need to ask" — covers preparing the report, never making the link.

- **yes** — `report.sh send --workdir W --project <project dir> --digest <the previewed digest>`.
  It sends nothing: it prints a GitHub "new issue" link carrying the previewed title and body. Give
  the user the link; the issue exists only once the user submits it on GitHub.
- **no** — delete the workdir. Nothing was sent.
- **a change** — make it in `W/fields`, run `prepare` and `preview` again, and ask again. The new
  preview has a new digest.

## Rules

- **Nothing leaves except through the link `report.sh send` prints.** No `git push`,
  `gh pr create`, `gh issue create` or API call of your own, no pasting the description anywhere
  else, no editing `payload.txt` by hand.
- **The link carries the payload's title and body only**: no diff, no file from the clone, no
  account or commit identity. `report.sh` has no pull-request route in this release: `prepare`
  refuses `--route pr`, and `send` refuses any payload whose route line is not the issue link.
- **The scrub is mechanical.** `prepare`, `preview` and `send` each refuse a payload naming a
  home-directory path, an e-mail address (other than `example.com` and GitHub no-reply), the
  machine's user, host or git names, the project's directory name or any of its file names that
  the plugin's own text does not already use, or a secret-shaped string. A refusal is never worked
  around; the description is rewritten in more general terms.
- **The preview is the payload.** `send` takes the digest the user was shown and refuses a payload
  that changed since. Nothing checks mechanically that the user answered the preview before `send`
  runs; that is safe only because `send` sends nothing — the user still reads and submits the
  issue on GitHub.
