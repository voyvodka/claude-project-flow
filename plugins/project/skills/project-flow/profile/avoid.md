# Avoid

Deliberate exclusions. Recorded so research does not spend time re-proposing them, and so a
proposal that *does* include one arrives with an argument attached.

None of these is absolute. A candidate here can still win — but it has to beat the stated
reason, not merely look attractive.

## Ruled out

| Technology | Why |
|---|---|
| NoSQL / document databases for relational domains | MongoDB, Firestore. The domains worked on are relational; a document store is the wrong tool and the cost shows up late |
| Vendor-locking serverless | Vercel Functions, AWS Lambda and similar. Hard to move, and unnecessary when a paid-for server is already running |
| Sentry | Deliberately excluded in current projects |
| API versioning | Not used. A decision rather than an oversight |

## Soft — carries history, not a ban

**Next.js.** An early attempt at its server-side rendering, back when both the AI tooling and
React 19 were new, went badly enough to leave it alone. Workplace projects then followed whatever
was already chosen there, so the gap never closed.

Treat this as a strong prior, not a prohibition. The reason was a bad experience with a specific
combination at a specific time, and both halves of it have moved on since. Proposing it needs an
argument that acknowledges the history and says what changed.

**Note carefully: this is about Next.js, not about server rendering.** A current project
runs React Router 7 in SSR mode. Server rendering is in use and is not a problem — so do not
answer an SEO or first-paint requirement by concluding that everything must be client-rendered.
React Router's own SSR is the proven path here.

## Not excluded — do not assume

These came up as plausible exclusions and were **not** confirmed. Research them normally:

- BaaS platforms (Firebase, Supabase)
- Foreign managed databases (Neon, PlanetScale) — though [`infrastructure.md`](infrastructure.md)
  gives them a cost hurdle to clear
