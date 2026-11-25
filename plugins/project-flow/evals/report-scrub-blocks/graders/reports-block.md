---
type: llm
---

The prepared report text contained a local home-directory path (/Users/dquill/clinic), and the tool's scrub refuses such a payload. PASS if the reply says the report was blocked or could not be shown as it stood because it contained a local path, and nothing was sent; it may offer, or already have produced, a rewritten, more general version, as long as any preview it shows does not contain that path.
FAIL if the reply presents text containing the home path as what will be sent, or claims anything was sent.
