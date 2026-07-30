# .NET Backend

The default for any business backend or API. C# / .NET 10 is the daily language — the thing that
can be written and, more importantly, *reviewed* at full speed.

Read [`code-style.md`](code-style.md) first; it carries the naming, comment and safety rules.

Reference: the layered backend of a business web app. See "Reference implementations" in [`README.md`](README.md#reference-implementations).

## Solution shape

**At full size**, a layered solution. Smaller projects carry the same conventions in fewer
projects — see "Scaling" in [`dotnet-api-contracts.md`](dotnet-api-contracts.md) for which splits
are earned when. Do not start here by default; start at one project and arrive here under
pressure.

| Project | Holds |
|---|---|
| `<Name>` | Host — startup, DI wiring, middleware pipeline |
| `<Name>.Api.General` | Admin and management endpoints, plus account/token surfaces |
| `<Name>.Api.Client` | Tenant endpoints |
| `<Name>.Data` | EF Core context, entities, migrations, repositories |
| `<Name>.Engine` | Domain and business rules |
| `<Name>.Validators` | FluentValidation validators, organised by area |

`Directory.Build.props` at the solution root carries shared properties — target framework,
`ImplicitUsings`, `Nullable`, version, authorship. Never set these per project.

**Two API layers, no versioning.** Versioning exists to let old and new coexist; with no legacy
consumer there is nothing to version against. `Api.Client` references `Api.General`, because the
base controllers live there.

A controller-only class library is **not reliably discovered** by MVC. The host must register it
explicitly: `AddControllers().AddApplicationPart(typeof(IApiClientAssemblyMarker).Assembly)`.
Skipping this produces 404s on every route in that project, with no error at startup.

## Endpoints

- **Base controllers** rather than per-controller attributes: one for any authenticated user, one
  for admin (`[Authorize(Roles = admin)]`), one for tenant scope. Public endpoints are explicitly
  `[AllowAnonymous]`.
- **A bare "any authenticated user" base is not an admin base.** An admin surface inheriting from
  it accepts a tenant token and returns 200. Admin controllers inherit the admin base — always.
- **Tenant membership means read.** If the base grants tenant access, every *mutating* action
  carries its own owner-role attribute. An unmarked write silently opens to every tenant member.
  Surfaces that are entirely owner-only are marked at class level instead.
- **Responses:** success is `OkResponse(dto)`; void and toggle actions return `NoContentResponse()`
  — **200 with the envelope body, never 204**. A 204 gives the client nothing to branch on.
- **Errors are thrown, not returned.** Middleware turns them into the envelope.
- `[ProducesResponseType<ApiResponse<T>>(200)]` on each action; the error contract is declared once
  at class level.

## Response envelope

`ApiResponse<T> { success, data, error, meta }` with `ApiError { code, message, details[], fields }`.

A `ValidationActionFilter` and an `ExceptionMiddleware`, both scoped to `/api`, produce it.

**Model-binding failures do not pass through the validation filter.** Malformed JSON, type
mismatches and oversized bodies fail before the action runs and need their own envelope path.
Anything that touches the envelope needs localisation wired into it separately.

## Validation and mapping

- **FluentValidation** in the validators project, grouped by area.
- **AutoMapper** registered through DI, matching by name.
- **Repositories and services** registered in one `ServiceRegistrationExtensions`, never ad hoc.
- **Lists** use a generic `ListRequest` / `ListResponse` pair with a filter operator set
  (`eq/neq/gt/lt/gte/lte/contains/in/between/isNull/notNull`) and a **`Filterable` allow-list** —
  a field outside it returns 400 rather than filtering on something unintended.

Watch what shape the filter runs against: after `ProjectTo<Dto>` it is a DTO property (a computed
one is fine); before it, an entity column. The two diverge and the failure is a silent empty list.

## OpenAPI

`Microsoft.AspNetCore.OpenApi`, one default document at `/openapi/v1.json`. Not Swashbuckle.

A schema transformer reflects FluentValidation rules into schema constraints, so the generated
client carries the same validation the server enforces. **This is why the document is not
optional** — the frontend client is generated from it.

## Data

- **PostgreSQL**, EF Core, migrations in the `.Data` project.
- **UTC end to end.** All timestamps `timestamptz`, connection `Timezone=UTC`, Npgsql strict UTC
  (never enable the legacy switch), `DateTime.UtcNow` everywhere, ISO-8601 with `Z` in JSON.
  Where a business day boundary matters — a subscription expiring — compute it in local calendar
  terms deliberately and say so; a user signing up at 01:00 should not lose a day.
- **Soft delete** is `Deleted` / `DeletedOn` / `DeletedBy` with **no global query filter**, so
  every repository query filters explicitly. Delete sets all three fields; never hard-remove.
- **Constraint violations map in one place** — the exception middleware, by SQL state: unique and
  foreign key to 409, not-null and check to 400, unknown to 500, and never leaking the database
  detail. Do not catch and map Postgres exceptions in repositories as well.

## Multi-tenancy

**Isolation is server-authoritative.** A tenant id arriving in a request body, query string or
route parameter is never trusted — the scope comes from the token claim.

Reads filter by the current tenant, creates assign it, updates and deletes verify ownership.
**An ownership violation returns not-found, not forbidden** — a 403 confirms the record exists.

**Never reuse an admin DTO on a tenant surface.** It works on the day it is written and leaks the
day a field is added to it.

## Auth

Short-lived access JWT with a database-backed rotating refresh token.

- Access token minutes are configuration, not a constant. Claims carry subject, jti, name, role
  and tenant.
- The refresh token is CSPRNG bytes; the database stores **only its SHA-256 hash**, with a
  revocation and replacement chain.
- **Rotation on every refresh, with reuse detection** — a replayed token revokes the whole family.
  The rotation must claim the token in a single conditional update; read-then-check-then-revoke
  lets two concurrent refreshes both succeed and produces two valid chains.
- **Password change and reset revoke every active refresh token.** Otherwise a stolen refresh
  token keeps minting access tokens after the password has changed.
- Account state gates are re-checked on refresh, not only at login.

Transport is httpOnly cookies, same-origin: an access cookie on `/`, a refresh cookie scoped to
the token endpoint. The `Authorization` header is **never read** — the cookie is the single
source. Tokens never appear in a response body. CSRF is a double-submit token with
`SameSite=Strict`. **CORS is enabled in Development only**; a same-origin deployment never needs
production origins, and adding them back reopens what the design closed.

A non-browser client — a mobile app, a device agent — needs a bearer token, and that is a
legitimate reason to run both. Say so explicitly rather than switching the whole system to bearer
tokens because one client needed them.

## Deployment shape

**Single deployable.** The frontend build output is served from the backend's `wwwroot`: one
publish, one origin, no CORS, and same-origin cookies work without special handling. SPA routing
is a guarded fallback, so `/api`, hub and media paths still return real 404s.

Splitting the frontend onto its own origin is a real decision — it changes the auth story first —
and needs a reason beyond habit.

**The coupling is real:** frontend and backend deploy together.

## Security pipeline

Order in the middleware pipeline is load-bearing and easy to break silently:

1. **Forwarded headers first** — scheme and client IP restoration. HSTS, HTTPS redirect, secure
   cookies and rate-limit partitioning all depend on it.
2. HSTS and HTTPS redirection outside Development.
3. Security headers, written in `OnStarting` rather than directly, so they still apply to error
   responses written downstream.
4. Rate limiting **after** authentication, so limits can partition by user.

**CSP: never `'unsafe-inline'` on `script-src`.** A build that produces no inline scripts needs
none; where backend-rendered HTML genuinely requires one, use a per-request nonce.
`'unsafe-inline'` on `style-src` is accepted — CSS-in-JS and React `style=` attributes cannot
carry a nonce.

Every anonymous or abuse-exposed endpoint — login, register, public surfaces, webhooks — carries
an explicit rate-limit policy. Server-to-server callbacks disable it instead: turning a retry into
a 429 turns a transient failure into a permanent one.
