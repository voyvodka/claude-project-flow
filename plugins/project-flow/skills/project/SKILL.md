---
name: project
description: Start, resume, or advance a project — asks questions before writing anything, researches, records decisions in docs/, then builds in approved increments
argument-hint: Optional rough description of the project idea
disable-model-invocation: true
allowed-tools: ["Skill"]
---

Load the `project-flow:project-flow` skill with the Skill tool now, then follow it exactly.

Do not answer, plan, or write anything before the skill is loaded. The skill decides which phase this invocation belongs to.

The user's opening input (may be empty — an empty value is normal and means "figure out where we are"):

$ARGUMENTS
