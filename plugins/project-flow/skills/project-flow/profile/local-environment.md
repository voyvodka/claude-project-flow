# Local Environment

The development machine. Read this before proposing anything that has to run locally, and before
the first commit of a new project.

Distinct from [`infrastructure.md`](infrastructure.md), which is where things are *hosted*.

> **This file is a template.** Fill it in, or put a personal copy at
> [`local/local-environment.md`](README.md#personal-overrides), which is read instead of this one
> and is never committed. Until then, ask rather than assume — especially about git identity.

## Git identity — the rule that bites

Record here which identity new projects commit under, and whether the machine's global git
config already carries a different one.

This matters more than it looks. When the global config holds an identity meant for other
repositories, a new repository picks it up unless told otherwise — and an address that belongs to
another context is often not even deliverable: the commits carry an author nobody can reach and
that no forge will link to an account.

**When the project needs an identity other than the global one, set it locally, in the repository,
at `git init` time:**

```
git config user.name  "<name>"
git config user.email "<email>"
```

Local, not global: the global config serves the machine's other repositories, so leave it as it
is unless the user asks.

Get this wrong and the first commits carry the wrong address into a repository
that may end up public. Rewriting author history afterwards is possible and unpleasant, so it is
worth doing at initialisation rather than discovering later.

When a repository is initialised, setting the local identity is part of that action, not a separate
favour. Say that it was set, and to what.

## Machine

Record the real limits: CPU architecture, total RAM, and how much of it the container runtime is
allowed to take. These are constraints, not trivia — a container runtime and an editor's language
services compete for the same memory.

The consequence for planning: a project that wants five containers running locally is proposing
something a modest machine will struggle with. Say so during the development-environment
discussion rather than discovering it when everything swaps. Prefer a compose file where optional
services can stay down, and a default profile that brings up only what the project needs today.

## Locally running containers

If the machine already hosts shared development services — databases, object storage, admin
interfaces — list them here, and note that they are **development infrastructure for several
projects at once**, not part of any one project.

The consequence: **a new project brings its own container rather than borrowing an existing
one**, on its own port and with its own name. Sharing one Postgres instance across projects is how
a migration in one drops a table in another.

Check what is actually up before assuming anything is available — this list drifts.
