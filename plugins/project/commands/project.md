---
description: Start, resume, or advance a project — asks questions before writing anything, researches, records decisions in docs/, then builds in approved increments
argument-hint: Optional rough description of the project idea
allowed-tools: ["Read", "Write", "Edit", "Glob", "Grep", "Bash", "AskUserQuestion", "Agent", "WebSearch", "WebFetch", "Skill", "TaskCreate", "TaskUpdate", "TaskList", "TaskGet"]
---

Load the `project:project-flow` skill with the Skill tool now, then follow it exactly.

Do not answer, plan, or write anything before the skill is loaded. The skill decides which phase this invocation belongs to.

The user's opening input (may be empty — an empty value is normal and means "figure out where we are"):

$ARGUMENTS
