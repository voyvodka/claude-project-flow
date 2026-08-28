# Infrastructure

Read this on every project. Existing infrastructure is usually the strongest argument in a
hosting decision and the one most easily forgotten.

> **This file is a template.** It ships with the questions, not the answers — the answers are
> specific to whoever runs the plugin. Fill it in, or put a personal copy at
> [`local/infrastructure.md`](README.md#personal-overrides), which is read instead of this one
> and is never committed.
>
> Until it is filled in, treat hosting as **fully open** and say so during Phase 2 rather than
> inventing a server that may not exist.

## What already exists

Record, concretely:

- **The server or platform** — provider, size, RAM, disk, region, monthly cost. Spec sheet
  numbers are not enough; see "Read the real headroom" below.
- **How deployment happens** — a PaaS, a CI pipeline, manual, or nothing yet. If something
  already owns the deployment path, a project must not hand-write a second one; the two
  eventually disagree.
- **What is already listening** — which ports are taken, what terminates TLS, how traffic is
  routed to an application. A design that assumes it can bind 443 is wrong on most shared boxes.
- **What else is already running on it.** A new application is planning against what is *left*,
  not what was bought.

## Read the real headroom, not the spec sheet

Measure free RAM and free disk on the actual machine and plan against those numbers.

Two things that decide designs and are usually missed:

- **Whether there is swap.** With none, memory exhaustion is an OOM kill rather than a slowdown:
  the container dies abruptly, under exactly the load that caused it. A stack that fits "just
  about" does not fit.
- **Disk fills quietly** — a database, uploaded media, rendered image variants, logs, and Docker
  images and layers. Any design storing several rendered sizes of every upload should have its
  growth estimated during research, not discovered at 90% full.

Resizing is usually easy and cheap. That is a decision to surface, not a silent assumption.

## Backups — what they do not cover

Disk-level or snapshot backups are **crash-consistent**: a running database captured that way is
a copy of its files mid-write. It will usually recover on start, and "usually" is the operative
word.

| Failure | Covered by snapshots? |
|---|---|
| Server lost, disk gone, needs rebuilding | **Yes** — this is what they are for |
| Rolled back wholesale to yesterday | Yes, with up to a day lost |
| A table dropped, a bad migration, corrupt rows | Only by restoring *everything* to a point in time |
| One tenant's data restored while others keep running | **No** |

A project needing the bottom rows still needs its own logical dump, scheduled and kept off the
same disk. That is a small piece of work, but it has to be **named** as work rather than assumed
away because "backups are on". Infrastructure backups and database backups solve different
problems; say so plainly when the subject comes up.

## DNS, domains and the edge

Record which domains exist, where DNS is hosted, and what the DNS provider's plan already
includes beyond DNS — edge functions, static hosting, object storage, caching. That is often the
cheapest path for anything static or edge-shaped, and it does not consume the server.

Two cautions worth stating out loud whenever an edge runtime is proposed: it is a *different*
runtime with different constraints, and its storage may sit outside the data-residency boundary
the rest of the stack assumes.

A project that needs a hostname most likely takes a subdomain of something that already exists.
Ask before assuming a new registration is wanted.

**Never write network addresses into this file** — read them from the provider console or the
deployment configuration when they are needed. This file is likely to be shared.

## No transactional mail until proven otherwise

Domain-level mail *forwarding* is not sending. It delivers mail addressed to a domain; it does
not send activation links, password resets, or notifications.

Any project with a login has a decision to make early, and it is easy to miss because email feels
like something that just works. Left unnamed, the plan quietly assumes a sender exists and the
gap surfaces during the increment that ships registration.

- **Sending from the server directly is not viable.** A fresh cloud IP has no reputation, most
  providers block outbound port 25 by default, and mail from an unwarmed address lands in spam
  even when everything is configured correctly.
- **Deliverability needs DNS work** — SPF, DKIM and DMARC on the sending domain. It is a step,
  and it is the step people skip.

Treat "which provider sends our mail" as a Phase 3 decision whenever a project has accounts, and
give it a line in the decisions file.

## Personal versus workplace

If personal and workplace projects run on different infrastructure, record both and the
differences — source hosting, CI, deployment target, package registries. The difference is easy
to carry across by accident, and a build diagnosed against the wrong one wastes an afternoon.

Private package feeds are worth a specific note: off the network they often **time out rather
than failing fast**, and a package already in the local cache still restores. The symptom is a
slow build with warnings, not an error.

## What this means for research

A managed provider is not competing against zero — it is competing against a server that is
already running and already paid for. Managed services have to earn their monthly cost against a
marginal cost of nothing.

That is a real hurdle, and it is not automatically decisive: managed services buy back operating
time, and time is the scarcer resource for a solo developer. Automatic backups, point-in-time
restore, version upgrades and failover all become the user's job on a self-hosted box.

State the trade honestly and let the user decide. What is not acceptable is a cost table that
prices a managed database at its list price while pricing the existing server at nothing without
mentioning what it does not include.

## Data residency

Record which jurisdiction the hosting sits in and which regime applies to the product's users.
Keep the data layer portable so that a customer demanding local residency is a migration measured
in days, not a rewrite. Do not build business logic on vendor-specific features.

## Free tiers

Check the licence, not just the price. At least one common platform restricts its free tier to
non-commercial use, which makes it unusable for anything intended to be sold — and the constraint
surfaces on the day the product starts earning, which is the worst possible day for it.
