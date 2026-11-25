---
max_turns: 20
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Bash, Write, Edit, Agent]
---

/project-flow:project Before Phase 3: we have now passed three phase gates in this project, and not once did the tool ask whether anything went wrong because of how project-flow itself is written, even though its own instructions say to ask at every gate. Twice that check would have caught a real problem. That check never fires; it's a defect in project-flow, not in this project.
