# Documentation / Marketing Site

**Astro**, with Tailwind. Static output, custom domain.

Reference: a product marketing site. See "Reference implementations" in [`README.md`](README.md#reference-implementations).

## Shape

- Astro with TypeScript, Tailwind for styling, pnpm.
- Static build. Where a page genuinely needs something dynamic, the host's own function runtime
  — a `functions/` directory on Cloudflare Pages — rather than turning the whole site into an
  application to serve one endpoint.
- The custom domain is set the host's way: on GitHub Pages a `public/CNAME` file (Astro's GitHub
  Pages deploy guide, checked 2026-10-24); on Cloudflare in its dashboard. Neither is an Astro
  feature, and the two do not combine — pick the host first.
- Lighthouse configuration checked in — performance on a content site is a requirement, not a
  nice-to-have, and checking it in makes it measurable rather than aspirational.

## Why Astro rather than the React SPA stack

Content sites want HTML by default and JavaScript only where it is needed. That is the opposite
of what the SPA stack optimises for, and the difference shows up as page weight and search
ranking on exactly the pages that exist to be found.

Reach for the SPA stack when the thing is an application that happens to have pages. Reach for
Astro when it is pages that happen to need a little interactivity.
