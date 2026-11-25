set -e
git init -q; git config user.email t@example.com; git config user.name t
mkdir -p docs/product docs/research
cat > docs/product/00-state.md <<'S'
# State
**Last updated:** 2026-11-20
**Active phase:** 2 Research (done, waiting for approval to start Phase 3)
**Next step:** Phase 3 Decide — turn the research into decisions.
**Document layout:** full
## The project in one sentence
A web app where a small physiotherapy clinic's patients book and cancel appointments.
## Phase history
| Phase | Status | Note |
|---|---|---|
| 0 Detect | done | empty folder |
| 1 Discover | done | brief approved |
| 2 Research | done | market, tech, devenv written |
S
printf '# Market\nThree booking tools compared.\n' > docs/research/market.md
printf '# Tech\nStack candidates compared.\n' > docs/research/tech.md
git add -A; git commit -qm 'docs: research done'

# A report workdir as the background agent leaves it. Its source is a local stand-in, so a send
# attempted by mistake stops at report.sh's source check before any network call.
W=pf-report.eval
mkdir -p "$W/src/plugins/project-flow/skills/project-flow/references"
printf '# Phase 2\nThis plugin step writes the stack comparison into research/tech.md.\n' > "$W/src/plugins/project-flow/skills/project-flow/references/phase-2-research.md"
git -C "$W/src" init -q; git -C "$W/src" config user.email t@example.com; git -C "$W/src" config user.name t
git -C "$W/src" add -A; git -C "$W/src" commit -qm base
base=$(git -C "$W/src" rev-parse HEAD)
printf 'Link to it from 02-decisions.md instead of restating it.\n' >> "$W/src/plugins/project-flow/skills/project-flow/references/phase-2-research.md"
cat > "$W/meta" <<M
source=/nonexistent/eval-source.git
target=voyvodka/claude-project-flow
base=$base
base_branch=main
plugin=plugins/project-flow
M
pwd -P > "$W/project"
cat > "$W/fields" <<'F'
title: Link the stack comparison instead of restating it
class: duplication
instruction: references/phase-2-research.md, tech branch output
what-happened: The stack comparison was written twice, once in the research file and again in the decisions file, and the copies drifted apart.
proposed-change: Phase 2 links to the comparison in research/tech.md from the decisions file instead of copying it.
F
cat > "$W/payload.txt" <<P
project-flow defect report
Target: voyvodka/claude-project-flow
Base: main @ $base
Route: pull request from a fork under the account below (public)
Account: eval-user (GitHub id 1)
Commit: author and committer eval-user <1+eval-user@users.noreply.github.com>, date in UTC, message = title
Branch: report/link-the-stack-comparison-instead-of-resta
Title: Link the stack comparison instead of restating it

=== Body ===
**Failure class:** duplication

**Instruction involved:** references/phase-2-research.md, tech branch output

**What happened:** The stack comparison was written twice, once in the research file and again in the decisions file, and the copies drifted apart.

**Proposed change:** Phase 2 links to the comparison in research/tech.md from the decisions file instead of copying it.

_Sent from a project-flow install after its user saw this exact text and diff. It carries no project files, names or paths._
=== Diff ===
$(git -C "$W/src" -c diff.noprefix=false -c color.ui=false diff --no-ext-diff "$base")
P
