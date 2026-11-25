# Developer Profile

How the developer works and where things run: code conventions and safety rails, the local
machine, hosting, documentation habits, repository layout. Read this index at the start of
Phase 1, and each file at the moment it applies.

**It holds no stack defaults.** Which language, framework or platform a project uses comes from
the user, from the project's own files, or from Phase 2 research — `SKILL.md` › Choosing the
stack. A preference recorded here would be a verdict on projects nobody has seen yet.

**Edit these files directly.** This directory is the one part of the plugin meant to be
personal. Everything in it is a **default, not a rule**: Phase 1 confirms it applies to the
project at hand. The one exception is the safety rails in
[`code-style.md`](code-style.md#safety-rails) — git, tests, migrations, shared databases. Those
are rules, and no phase relaxes them on its own.

## Personal overrides

`profile/local/` is **not committed**. Any file placed there is read *instead of* the file with
the same name one directory up.

```
profile/infrastructure.md          committed — the template
profile/local/infrastructure.md    ignored by git — the real one, read in preference
```

This is what keeps machine names, hostnames, open ports, e-mail addresses and workplace
repository paths out of a public repository while the plugin still runs against real answers
locally.

> **This only works when the plugin runs from a copy you own** — a clone, or a folder under a
> `skills/` directory. A marketplace install is copied into a versioned plugin cache: the clone it
> was built from never contained `local/` (it is gitignored), and a `local/` created inside the
> cache is deleted the next time the plugin updates.
>
> The failure is silent: nothing errors, the templates are read instead, and the tool proceeds
> as if the subject were unanswered. If you install from a marketplace, either edit the committed
> files directly and accept that an update overwrites them, or run the plugin from a clone. See
> the repository README.

[`infrastructure.md`](infrastructure.md), [`local-environment.md`](local-environment.md) and
[`avoid.md`](avoid.md) ship as templates and hold no real data until they are filled in. Until
one is filled in or overridden, treat its subject as **genuinely open** and ask, rather than
inventing a server, an identity or an exclusion.

## Index

| File | When to read it |
|---|---|
| [`code-style.md`](code-style.md) | **Always** — comments, dependencies, safety rails, doc order |
| [`local-environment.md`](local-environment.md) | **Always** — git identity, machine limits, local containers |
| [`infrastructure.md`](infrastructure.md) | Every project — hosting, CI, deployment target |
| [`avoid.md`](avoid.md) | Phase 2, before proposing candidates — only if it lists anything |
| [`repo-layout.md`](repo-layout.md) | Phase 3, when deciding how the top level is arranged |
| [`project-docs.md`](project-docs.md) | Phase 4, before writing `CLAUDE.md` |

## Constraints that always apply

Record the ones that are true everywhere, so no project has to rediscover them. Two that are
worth stating explicitly if they apply:

- **Jurisdiction.** Which data-protection regime covers the product's users, and where the
  hosting sits relative to it. This decides more designs than it looks like it should.
- **Cost discipline.** If a server is already paid for, it is a sunk cost and paid managed
  services need a real argument — see [`infrastructure.md`](infrastructure.md) for how to make
  that comparison honestly rather than by pricing the existing box at zero.
