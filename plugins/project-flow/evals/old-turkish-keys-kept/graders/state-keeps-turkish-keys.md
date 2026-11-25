---
type: regex
pattern: 'Active phase|Next step|Document layout|Phase history|Last updated'
match: not_contains
target: { source: file, path: docs/product/00-state.md }
---
