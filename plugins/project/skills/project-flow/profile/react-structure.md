# React Structure

Directory layout, and the patterns that keep page code thin.
[`react-frontend.md`](react-frontend.md) says what the stack is; this file is how it is arranged
and how duplication is kept out.

## Layout

```
frontend/
  package.json · vite.config.ts · tsconfig.json · eslint.config.ts
  openapi-ts.config.ts · openapi/v1.json        committed spec
  public/locales/{tr,en}/{ns}.json
  src/
    main.tsx                                     mount
    App.tsx · AppLayout.tsx                      router + chrome
    app/BaseProviders.tsx                        i18n · query · theme · locale — ONE stack
    api/
      generated/                                 codegen output — gitignored, never hand-edited
      runtime.ts                                 shared axios: relative base, credentials, XSRF
      index.ts                                   barrel: re-export + unwrap → "@/api"
    theme/                                       design tokens + css variable bridge
    providers/                                   query client, auth context
    config/nav.tsx                               ONE registry: route and menu both derive from it
    lib/
      hooks/                                     generic, UI-agnostic
      services/core/                             shared axios, request dedup
      realtime/                                  refcounted singleton connection + event hook
      stores/                                    persisted client state
      types/ · utils/ · format/ · domain/
    components/
      ui/ · data/ · forms/ · layout/
    pages/<area>/
      <Page>.tsx
      components/ · hooks/
      <area>Service.ts · <area>Logic.ts · <area>Types.ts
```

Two structural rules do most of the work:

**Feature colocation.** A page's service, logic, types and private components live beside it, not
in a global folder split by kind. Everything a feature needs is in one directory, and deleting the
feature deletes all of it.

**One navigation registry.** Adding a page is one line in `config/nav.tsx`; route and menu entry
both come from it. Two lists in two files drift, and the symptom is a route that exists but is
unreachable.

## Adding a feature

The whole flow, in order:

1. Write the backend endpoint.
2. Regenerate the client; commit the refreshed spec.
3. `pages/<area>/<area>Service.ts` wraps the generated SDK and unwraps the envelope.
4. Page composes shared components with a query hook.
5. One line in `config/nav.tsx`.

If a step needs a new shared component, that is a signal — see below.

## Service layer over SDK

Never call the generated SDK from a component. Each area gets a service module that wraps it and
unwraps the envelope.

Reads go through the generated function. Writes that need field-level error mapping go through the
shared axios instance directly, so the error details survive into the form. That asymmetry is
deliberate and worth knowing before "simplifying" it.

## The shared inventory

Build these once; a page that hand-rolls an equivalent has created a second definition of a solved
problem.

| Kind | What exists |
|---|---|
| Layout | page header, list card (search / filter / new), table card, form section, form columns |
| Data | server-driven table, list query hook, server table hook, detail query hook |
| Actions | row actions, action column, CRUD action column, confirm hook |
| Forms | controlled field, lookup select, readonly field, form layout presets, API form error hook |
| CRUD | CRUD list hook, CRUD submit hook, reorder queue |
| Utility | debounce hook, format helpers, modal preset |

Import the modal preset rather than the UI library's modal directly — the preset carries the
project's defaults, and using the raw one reintroduces the inconsistency the preset removed.

## Keeping duplication out

**When the same shape appears a third time, extract it.** Not the second — two occurrences is a
coincidence and the wrong abstraction costs more than the duplication. Three is a pattern.

**A page should read as composition.** If a page file contains layout primitives, manual loading
flags, or its own table wiring, the shared set is missing something. Add it there rather than
solving it locally; the next page has the same problem and will solve it differently.

**Policy lives in one module, referenced everywhere.** A password rule, a currency format, a date
format, a status-to-label map — written once, imported. Re-implementing a validation rule inline
forks the policy silently, and the fork is only found when the two disagree in front of a user.

**Cross-entity mutations invalidate by prefix.** Query keys are entity-prefixed, so an operation
touching several entities invalidates each prefix rather than the one list the page happens to
show. An import endpoint writing four entity types is the case that exposes this; the page it runs
from shows none of them.

**Sequential writes need a queue, not fire-and-forget.** Drag-reorder posts absolute positions, so
two quick drags racing can land out of order and lose the user's last action. Chain them, and
invalidate only when the queue drains — invalidating per request refetches mid-flight and
overwrites local order with stale data.

## Robustness

**Guard every stored-JSON read, and put an error boundary at the root.** An unguarded `JSON.parse`
of persisted state throws during the first render and turns a corrupt value into a permanently
white screen. The boundary belongs inside the provider stack so theme and translation still work
in the fallback, and it needs an escape hatch that clears the bad storage.

**Normalise the API base URL in one place.** A trailing slash plus a leading-slash path produces a
double slash and a 404 that looks like a routing bug.

**Declare a CSS variable before using it.** A variable not in the generation map resolves to
nothing, silently, with no fallback.
