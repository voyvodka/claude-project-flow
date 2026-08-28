# React Frontend

The default for any web interface. Every current project uses the same shape, which makes it the
most reliable default in this profile.

Read [`code-style.md`](code-style.md) first.

Reference: one business UI and one deliberately smaller project. See "Reference implementations" in [`README.md`](README.md#reference-implementations).

## Stack

**React 19 + TypeScript + Vite.** A pure SPA with React Router for applications; React Router's
own SSR mode where a public page needs to be indexed.

| Concern | Choice |
|---|---|
| UI library | Ant Design for business interfaces; Tailwind for everything else |
| Server state | TanStack Query |
| Client state | Zustand, persisted where it earns it (theme, language, sidebar) |
| Cross-cutting state | React Context (auth) |
| Forms | React Hook Form + zod |
| API client | Generated — never hand-written |

The three state layers are a deliberate split, not accumulation: server data belongs to TanStack
Query, durable client state to Zustand, ambient values to Context. Putting server data in Zustand
is the mistake the split exists to prevent. Do not write `state.loading` flags or manual aborts —
the query layer owns both.

## Hard rules

- **Path alias `@/*` → `src/*`.**
- **Never import from the generated API directory.** Import from the `@/api` barrel. Generated
  code is gitignored; the OpenAPI spec is committed, so CI can regenerate without a running
  backend.
- **TypeScript is pinned at 6.x only until lint tooling supports 7.** Codegen and lint break on a
  major bump ahead of their own support. This is a temporary block with a named unblock condition,
  not a preference — see [`code-style.md`](code-style.md).
- **No `.js` / `.jsx`.** Configuration files included.
- Feature colocation: pages under `pages/<area>/`, with their service beside them.

## API client generation

`@hey-api/openapi-ts`, generating typescript + sdk + tanstack-query + zod + client-axios from the
backend's OpenAPI document.

Wrap the SDK in a service layer per area rather than calling it from components. Reads go through
the generated function; writes that need field-level error mapping go through raw axios so the
error details can be fed back into the form.

A hand-written client drifts from the contract silently, and the drift surfaces as a runtime error
in front of a user. Regenerate and commit the spec whenever the backend contract changes — a CI
gate comparing the two is worth having.

## Shared components

Build a shared set once and never hand-roll page-level equivalents: page header, list card, table
card, server-driven table, detail modal, row actions, controlled field, lookup select, form
section, readonly field, confirm hook, CRUD list hooks, debounce hook, API-form-error hook, format
helpers.

The rule is not "prefer the shared component" — it is that a page which hand-rolls one has
introduced a second definition of a solved problem, and the two diverge.

## UI conventions

These are the ones that get re-litigated, so they are written down.

- **A row action that opens a page is a link.** Give it an `href`, not an `onClick`, so it renders
  an anchor and cmd-click or middle-click opens a new tab. Actions that open a modal stay buttons.
- **The action column is the first column, with an empty header.** Put it at the head of the
  column array; a `fixed: "left"` alone does not reorder. Bordered small icon buttons, grouped
  when there is more than one. The detail icon is a magnifier.
- **Filters are always visible, unlabelled, placeholder-driven.** No toggle, no badge. Each
  control carries its field name as placeholder and **fixes its own width** — without that, adding
  a selection shifts every neighbour. Multi-selects cap their tag display responsively.
- **Full-page show and edit forms are horizontal** — label beside input, left-aligned, fixed label
  column, fields half-width by default. **Modal forms are vertical.** Public auth pages are the
  one exception: narrow centred card, vertical.
- **Show mode uses disabled inputs, not a description list.** A boolean in show mode is a disabled
  switch — never the strings "Yes" and "No" in a text box.
- **Detail and sub-lists open in a modal, never a drawer.** There are zero drawers in these
  applications, deliberately. Do not introduce one.
- **Editing a rich entity is an in-page show/edit toggle, not a modal.** A `mode` state, readonly
  fields in show, controlled fields in edit, and the toolbar in the header. Creating from a list
  can still be a modal; editing from a list row navigates to the detail page.
- **Two-column layout with centred section dividers** on detail and full-page forms. Do not
  auto-fill a flat grid and let sections fall where they may.

## Forms

React Hook Form with zod resolvers, wrapped in a `ControlledField` so field wiring is written once.
Server-side validation errors map back onto their fields through a dedicated hook — a validation
failure belongs on the field that caused it, not in a toast.

Shared policy lives in one place and is used, not re-implemented. A password field uses the shared
password schema and the shared requirements component; writing `min(6)` by hand forks the policy.

## i18n

- `useTranslation("ns")`, namespaces split per feature, Turkish fallback. No hardcoded strings.
- **A namespace must be declared, not merely prefixed.** Only the common namespace is preloaded;
  the rest load lazily from the `useTranslation` call. An undeclared namespace is never fetched and
  renders the raw key.
- A CI gate is worth the effort: undeclared namespaces, missing keys, parity between languages and
  interpolation-token parity all fail the build; unused keys warn. Dynamically constructed keys and
  keys for parked features need an explicit registry so the gate does not delete them.
- **Do not translate server messages on the client.** The API localises its own copy from
  `Accept-Language`. Client-side zod messages are a separate channel.

## Realtime

One hub for the application, not one per feature. Typed client interface, a refcounted singleton
connection on the frontend, events invalidating query caches. **The hub carries signals; content
stays in REST.** Broadcast after the write succeeds, not before.

## Quality gates

`typecheck && lint && build && i18n-check` — all four green before a page is considered done.
