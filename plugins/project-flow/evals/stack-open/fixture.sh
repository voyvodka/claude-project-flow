set -e
git init -q; git config user.email t@example.com; git config user.name t
mkdir -p docs/product
cat > docs/product/00-state.md <<'S'
# State
**Last updated:** 2026-11-20
**Active phase:** 1 Discover (in progress)
**Next step:** Remaining blocking items: constraints and existing skill.
**Document layout:** full
## The project in one sentence
A web app where a small physiotherapy clinic's patients book and cancel appointments.
## Phase history
| Phase | Status | Note |
|---|---|---|
| 0 Detect | done | empty folder |
| 1 Discover | in progress | round 2 |
S
cat > docs/product/01-brief.md <<'B'
# Project Brief
## 1. Problem
Patients phone the clinic to book; the receptionist keeps a paper diary and double-books.
## 2. Users
About 300 patients and 2 receptionists at one clinic.
## 3. Main flow
1. Patient picks a therapist and a free slot
2. Patient confirms with phone number
3. Receptionist sees it in the day view
## 4. Success criterion
Within a month, 60% of bookings arrive through the app and no slot is double-booked.
## 5. Out of scope
Payments, insurance claims, video sessions.
## 6. Constraints
(open)
B
git add -A; git commit -qm 'docs: discovery round 2'
