# Defect Report

When this tool's own instructions produced a bad outcome (`self-improvement.md` › The distinction
that matters), the fix belongs in the tool's source repository, not in this install: an install's
files are replaced on the next update. This file turns such a finding into a pull request from the
user's own GitHub account — or, without a `gh` session, into a prefilled issue link — while the user
keeps working, and with nothing personal in what leaves the machine.

The report script is the path named in `SKILL.md` › Routing; this file calls it `report.sh`. Run it
with `bash`.

## What the user sees

Two yes/no questions, nothing else:

1. **Whether to prepare a report.** At a phase gate or increment close, or in the reply to the
   user's own complaint about the tool — never in the middle of a task. Check `gh auth status`
   silently first, then ask one line, in the user's language:
   - with a `gh` session: *This looks like a defect in project-flow itself: <one abstract line>.
     Shall I prepare a fix in the background and open a pull request from your GitHub account? You
     will see exactly what would be sent first.*
   - without one: the same, ending *…and give you a prefilled issue link to submit yourself?*

   Ask it once per finding. A no ends it: nothing is written or kept.
2. **Whether to send exactly the preview.** Asked once the background work is ready (below).

## After the first yes

Start a `general-purpose` agent with the Agent tool, `model: "sonnet"`, `run_in_background: true`,
with the brief below filled in. Then carry on with the user's work; say in one line that the report
is being prepared. The brief carries the finding only in abstract terms — no quotes, no project or
person names — because the agent writes the text that leaves.

```
You fix one defect in the project-flow plugin's own instructions, in a fresh clone of its source
repository, and leave a report payload for the user to preview. You send nothing: the clone cannot
push, and sending happens later in the main session after the user approves.

Defect — class: <...>; instruction involved: <...>; what happened: <...>; proposed change: <...>
Report script: <report.sh path>. Project directory (scrub input only): <path>
Do not read, list or quote anything inside the project directory.

1. `bash <report.sh> clone` prints a workdir W; the plugin is at W/src/plugins/project-flow/.
2. If the source already fixes it (the install may be older), stop: status "already fixed", with
   file and line.
3. Make the smallest change that removes the cause (W/src/plugins/project-flow/skills/project-flow/
   references/self-improvement.md, How to fix). Only files under W/src/plugins/project-flow/, text
   only, no commit.
4. Write W/fields: exactly five lines, English, abstract, no quotes, names or outside paths:
   title: <imperative, at most 80 characters>
   class: <failure class>
   instruction: <plugin file and rule>
   what-happened: <general terms, at most 500 characters>
   proposed-change: <what the diff changes and why, at most 500 characters>
5. `bash <report.sh> prepare --workdir W --project <project dir>`. On BLOCKED, rewrite the named
   text in more general terms and rerun; never work around a finding. Stop after three blocks.

Reply with four lines: workdir: W / route: pr|issue / status: prepared|blocked|already fixed /
one sentence on the change. Never run preview or send; never push, fork or open anything on GitHub.
```

## When the agent finishes

At the end of the next reply — not in the middle of the user's task:

- **prepared** — run `report.sh preview --workdir W --project <project dir>` and paste its output
  **verbatim** in a code block: every line between the BEGIN and END markers, including the whole
  diff, and the `Digest:` line. Do not summarise, shorten or reformat it. Then ask: *Send exactly
  this?* **End the reply there.**
- **blocked** — say which kinds of finding blocked it (home path, e-mail address, user or machine
  name, project name or file name, path outside the plugin) and that nothing was sent. Offer to
  retry with a more general description; a retry is a new first question.
- **already fixed** — say so with the file, and suggest updating the plugin.

## After the second answer

Only a message the user sends after seeing the preview counts. An approval given earlier — "open
the PR", "send it", "you don't need to ask" — covers preparing the report, never sending it.

- **yes** — `report.sh send --workdir W --project <project dir> --digest <the previewed digest>`.
  On the pull-request route it opens the pull request (from a fork when the user cannot push to the
  repository) and prints its URL; on the issue route it prints the link for the user to open and
  submit. Give the user the URL.
- **no** — delete the workdir. Nothing was sent.
- **a change** — make it in `W/src` or `W/fields`, run `prepare` and `preview` again, and ask
  again. The new preview has a new digest.

## Rules

- **Nothing leaves except through `report.sh send`.** No `git push`, `gh pr create`,
  `gh issue create` or API call of your own, no pasting the description anywhere else, no editing
  `payload.txt` by hand.
- **What is sent is the payload and only the payload**: target repository, route, branch, commit
  identity (the account's GitHub no-reply address, the date in UTC), title, the fixed-shape body,
  and on the pull-request route a diff limited to `plugins/project-flow/`. The issue route sends no
  diff.
- **The scrub is mechanical.** `prepare`, `preview` and `send` each refuse a payload naming a
  home-directory path, an e-mail address (other than `example.com` and GitHub no-reply), the
  machine's user, host or git names, the project's directory name or any of its file names that
  the plugin's own text does not already use, a secret-shaped string, or a path outside the plugin.
  A refusal is never worked around; the description is rewritten in more general terms.
- **The preview is the payload.** `send` takes the digest the user was shown and refuses a payload
  that changed since, and it rebuilds the commit from the previewed diff rather than from the
  agent's working copy.
- **The second yes is a turn boundary.** A plugin hook refuses `send` unless the user has submitted
  a message after the session's latest preview, and refuses pushes or pull-request and issue
  creation run directly from a report workdir.
