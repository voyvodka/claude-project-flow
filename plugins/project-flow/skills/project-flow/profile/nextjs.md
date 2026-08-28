# Next.js

Read this **only if Next.js has actually been chosen.** It is not the default — see
[`avoid.md`](avoid.md) for the history, and [`react-frontend.md`](react-frontend.md) for what is.

## The rule that matters most

**If Next.js is chosen, build it the Next.js way.** Use the current App Router idioms and the
project structure the framework itself documents.

The failure mode to avoid is transplanting the SPA architecture into it: a client-only tree under
one root route, every page marked `'use client'`, all data fetched through a query client, routing
fought rather than used. That produces the SPA's complexity plus Next's build weight and returns
nothing — and it is the natural thing to do when arriving from the SPA stack, because every habit
points that way.

Choosing Next.js means choosing server rendering, server components and file-based routing. If a
project does not want those, it does not want Next.js — the SPA stack is right there, and React
Router's own SSR mode covers the middle ground.

## Structure

Folders under `app/` are route segments, and colocation is the organising principle: files a route
needs live in that route's folder rather than in a global directory split by kind.

- **Private folders** — prefix with `_` to keep a folder out of routing while colocating it with
  the route that uses it. This is the mechanism that makes colocation safe.
- **Route groups** — `(name)` folders organise without adding a URL segment. Use them to separate
  areas that share a layout.
- **Route files** — `page.tsx`, `layout.tsx`, `loading.tsx`, `error.tsx`, `not-found.tsx` and
  route handlers are conventions, not choices. Do not invent parallel mechanisms for them.
- Genuinely shared code goes up a level, not into every route folder. The same three-occurrence
  rule from [`react-structure.md`](react-structure.md) applies.

## The server/client boundary

**Components are Server Components by default.** `'use client'` marks a boundary, and everything
imported below it becomes client code.

Push the directive **as far down the tree as it will go.** Marking a page as client because one
button inside it needs state pulls the whole subtree across the boundary — this is the single
biggest structural mistake in an App Router codebase, and it is invisible until the bundle is
measured.

The canonical shape: a Server Component page fetches data and exports metadata, then renders a
small client component for the interactive part.

## Data

Fetch in Server Components. Mutate through Server Actions.

That displaces two things carried over from the SPA stack:

- **A generated API client has no job here** if the backend is Next itself — the server component
  calls the data layer directly. It stays relevant only when Next fronts a separate .NET or Go API,
  in which case the generation setup from `react-frontend.md` still applies, called from the server
  side.
- **TanStack Query shrinks to the client islands** that genuinely need client-side caching or
  optimistic updates. Do not install it reflexively and route all data through it — that reinstates
  the SPA and discards the reason for choosing Next.

Forms keep React Hook Form and zod for validation, with the zod schema shared between the client
form and the server action so one definition validates both sides.

## What carries over unchanged

From [`code-style.md`](code-style.md) and [`react-structure.md`](react-structure.md):

- TypeScript everywhere, no `.js`/`.jsx`, latest stable.
- Path alias for `src`.
- Shared component inventory; a page reads as composition.
- Policy in one module — password rules, formatting, status maps.
- The three-occurrence rule before extracting an abstraction.
- Guard stored-JSON reads; error boundaries where the tree can throw.

## Before writing any of it

Check the current documentation rather than working from memory. App Router conventions have moved
more than most, and a pattern that was correct two versions ago is the kind of thing that produces
confidently wrong code — which is exactly the risk that put Next.js on the soft-avoid list in the
first place.
