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
