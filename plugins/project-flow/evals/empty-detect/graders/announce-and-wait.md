---
type: llm
---

PASS if the reply says the folder is empty or new, names discovery (Phase 1) as the next step, and ends by asking the user for approval to start.
FAIL if it starts the checklist questions as if approval was already given, writes code, or does not ask for approval.
