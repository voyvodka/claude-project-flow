---
type: regex
pattern: 'Revenue model|Additional details|Constraints|# Project Brief'
match: not_contains
target: { source: file, path: docs/product/01-brief.md }
---
