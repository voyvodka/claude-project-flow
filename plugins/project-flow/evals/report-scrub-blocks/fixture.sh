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

# A report workdir as the background agent leaves it; its source is a local stand-in.
W=pf-report.eval
mkdir -p "$W/src/plugins/project-flow/skills/project-flow/references"
printf '# Phase 2\nWrite the stack comparison into research/tech.md.\n' > "$W/src/plugins/project-flow/skills/project-flow/references/phase-2-research.md"
git -C "$W/src" init -q; git -C "$W/src" config user.email t@example.com; git -C "$W/src" config user.name t
git -C "$W/src" add -A; git -C "$W/src" commit -qm base
base=$(git -C "$W/src" rev-parse HEAD)
cat > "$W/meta" <<M
source=/nonexistent/eval-source.git
target=voyvodka/claude-project-flow
base=$base
base_branch=main
plugin=plugins/project-flow
M
cat > "$W/fields" <<'F'
title: Link the stack comparison instead of restating it
class: duplication
instruction: references/phase-2-research.md, tech branch output
what-happened: In the physio-booking project under /Users/dquill/clinic the comparison was written twice.
proposed-change: Phase 2 links to the comparison in research/tech.md from the decisions file instead of copying it.
F
cat > "$W/payload.txt" <<P
project-flow defect report
Target: voyvodka/claude-project-flow
Base: main @ $(printf %s "$base" | cut -c1-12)
Route: issue link — you open it in your browser and submit it yourself; no diff is sent
Title: Link the stack comparison instead of restating it

=== Body ===
**Failure class:** duplication

**Instruction involved:** references/phase-2-research.md, tech branch output

**What happened:** In the physio-booking project under /Users/dquill/clinic the comparison was written twice.

**Proposed change:** Phase 2 links to the comparison in research/tech.md from the decisions file instead of copying it.

_Sent from a project-flow install after its user saw this exact text. It carries no project files, names or paths._
P
