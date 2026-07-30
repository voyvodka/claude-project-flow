# .NET API Contracts

The concrete shapes. [`dotnet-backend.md`](dotnet-backend.md) says what the architecture is; this
file is what to actually write, so a new project reproduces it without reading another repository.

Everything here is repo-local by design — defined inside the project, not inherited from a shared
library. A response envelope owned by a shared package cannot be changed when one project needs it
to change.

## Scaling: the contract is fixed, the structure is not

This applies to most .NET work started here, **at the size the project actually is.** Read that
distinction before copying anything.

**Invariant — every API, however small:**

- The `ApiResponse<T>` envelope and `ApiError` shape.
- Errors thrown, shaped by one exception middleware. Never returned ad hoc.
- `sealed record` DTOs, camelCase, never renamed across the mapping boundary.
- A published OpenAPI document — it is the client's contract, not documentation.
- 200 with an envelope for void actions, never a bare 204.
- UTC end to end.
- FluentValidation for input.
- The list contract, wherever there is a list, allow-list included.

These cost nothing at small scale and are expensive to retrofit, which is what makes them the
baseline rather than a target.

**Scales — and the trigger is a second consumer, not size.**

A folder does not become a project because it got big. It becomes a project when something outside
the host needs to reference it, and a folder cannot be referenced. That is the whole mechanic, and
it keeps the decision honest — "this is getting large" is a feeling, "the job scheduler needs these
rules" is a fact.

| Split | Earned when |
|---|---|
| `.Data` | Something other than the host reads the entities — a second API project, a worker, a migration tool |
| `.Engine` | Rules are needed by something that is not a controller: background jobs, a second surface, a console entry point |
| `.Validators` | More than one project needs them, and `.Data` cannot hold them because it sits below |
| **A second API project** | The surfaces deploy or evolve separately, or need different dependencies. **Not** merely because there are two audiences |
| A base-controller hierarchy | More than one authorisation posture exists — this is a *class*, and needs no project split |
| A realtime hub | Something actually pushes |

Note the fourth and fifth rows together: **two audiences is a base-controller problem, not a
project-layout problem.** An admin surface and a tenant surface live perfectly well in one project
with two base classes. Splitting them into separate assemblies is a build and deployment decision,
and it brings its own cost — controller discovery across assemblies stops being automatic and has
to be registered explicitly, which is a silent 404 when forgotten.

A small API is **one project with folders**, carrying the full envelope and conventions. That is
not a lesser version of the shape; it is the same shape at the size the work is.

Extracting ahead of a real second consumer is apparatus. It is read into context on every session,
it adds a reference graph to reason about, and it is reversed far less often than it is created.

## Response envelope

```csharp
public sealed record ApiResponse<T>
{
    public bool Success { get; init; }
    public T? Data { get; init; }
    public ApiError? Error { get; init; }
    public ApiMeta? Meta { get; init; }

    public static ApiResponse<T> Ok(T data, ApiMeta? meta = null)
        => new() { Success = true, Data = data, Error = null, Meta = meta };

    public static ApiResponse<T> Fail(ApiError error, ApiMeta? meta = null)
        => new() { Success = false, Data = default, Error = error, Meta = meta };
}

public sealed record ApiError
{
    public string Code { get; init; } = string.Empty;
    public string Message { get; init; } = string.Empty;
    public IEnumerable<ApiValidationErrorDetail>? Details { get; init; }
    public object? Fields { get; init; }
}

public sealed record ApiValidationErrorDetail
{
    public string Field { get; init; } = string.Empty;
    public string Code { get; init; } = string.Empty;
    public string Message { get; init; } = string.Empty;
    public IReadOnlyDictionary<string, object>? Params { get; init; }
}

public sealed record ApiMeta
{
    public string? RequestId { get; init; }
}
```

`Code` is what the client branches on; `Message` is for humans and is localised **server-side** —
see error localisation in [`dotnet-backend.md`](dotnet-backend.md). `Details` carries per-field
validation failures, which is what lets a form put each error back on the field that caused it.
`Params` exists so a message can be re-rendered in another language from its parts rather than
its text.

## List contract

```csharp
public sealed record ListRequest(
    int Page = 1,
    int PageSize = 10,
    IReadOnlyList<SortItem>? Sort = null,
    IReadOnlyList<FilterItem>? Filters = null,
    string? Search = null
);

public sealed record SortItem(string Field, string Dir);          // Dir: "asc" | "desc"
public sealed record FilterItem(string Field, string Op, object? Value);

public sealed record ListResponse<T>(
    IReadOnlyList<T> Items,
    int Page,
    int PageSize,
    int TotalItems,
    int TotalPages
);

public sealed record ListFields(
    IReadOnlyList<string> Sortable,
    IReadOnlyList<string> Filterable,
    IReadOnlyList<string> Searchable
);
```

Lists are `POST {resource}/list` — a filter set does not fit in a query string, and pretending it
does produces encoding bugs.

The endpoint reduces to one call: `query.ToListResponse(request, fields, defaultSort)`, with the
extension living beside the other queryable helpers. Everything above it is composition.

**`ListFields` is an allow-list and the security boundary.** Field names are camelCase, matched
case-insensitively against the projected row. A field outside the list returns 400 rather than
filtering on something the endpoint never meant to expose.

Operators: `eq` `neq` `gt` `lt` `gte` `lte` `contains` `in` `between` `isNull` `notNull`.

Two traps worth knowing before debugging an empty list:

- **Filter against the right shape.** After `ProjectTo<Dto>` the filter runs on DTO properties, and
  a computed property is fair game. Before it, on entity columns. The two diverge silently.
- **`isNull` still requires a nullable field.** On a non-nullable one the expression builder throws
  and the request 400s.
- **A page size cap and a full-fetch page size have to agree.** A drag-reorder list that pulls a
  whole bucket in one page will hit a validator cap set for normal paging, and the symptom is every
  list rendering empty while the data is fine.

## Base controller

```csharp
[ApiController]
[Authorize]
[ProducesResponseType<ApiResponse<object>>(400)]
[ProducesResponseType<ApiResponse<object>>(401)]
[ProducesResponseType<ApiResponse<object>>(403)]
[ProducesResponseType<ApiResponse<object>>(404)]
[ProducesResponseType<ApiResponse<object>>(409)]
[ProducesResponseType<ApiResponse<object>>(500)]
public abstract class ApiBaseController : ControllerBase
{
    protected int  CurrentUserId   { get; }   // sub / NameIdentifier claim
    protected int? CurrentClientId { get; }   // tenant claim, null for tenant-less users

    protected ApiMeta BuildMeta();            // stamps the request correlation id

    protected ActionResult<ApiResponse<T>> OkResponse<T>(T data, ApiMeta? meta = null);
    protected ActionResult<ApiResponse<T>> CreatedResponse<T>(T data, ApiMeta? meta = null);
    protected ActionResult<ApiResponse<T>> CreatedResponse<T>(string actionName, object routeValues, T data, ApiMeta? meta = null);
    protected ActionResult<ApiResponse<object>> NoContentResponse();
    protected ActionResult<ApiResponse<object>> FailResponse(int statusCode, ApiError error, ApiMeta? meta = null);
}
```

The error status codes are declared **once**, at class level, so no action repeats them.

Three subclasses, and which one a controller inherits from is a security decision:

| Base | Grants |
|---|---|
| `ApiBaseController` | Any authenticated user — **no role requirement** |
| `ApiAdminBaseController` | `[Authorize(Roles = admin)]` |
| `ApiClientBaseController` | Tenant scope, resolved from the claim |

**An admin surface must not inherit the bare base.** It accepts a tenant token and returns 200 —
a real finding in a real audit, across several controllers at once.

**`NoContentResponse()` returns 200 with an empty envelope, never a bare 204.** The reason is
concrete: the generated client unwraps `ApiResponse<T>`, and a 204 has nothing to unwrap.

**Prefer throwing over `FailResponse`.** Domain exceptions — not-found, forbidden, conflict,
bad-request, validation — are shaped into the envelope by the exception middleware, in one place.
`FailResponse` exists for the case that genuinely needs a caller-chosen status.

## DTOs

`sealed record`, clean camelCase, `get; init;`. One per surface — never share a DTO between an
admin endpoint and a tenant one. It works the day it is written and leaks the day a field is added.

**Property names are never renamed across the mapping boundary.** AutoMapper matches by name; a
rename converts a compile-time contract into a silent runtime null.

Where a DTO needs a derived URL or a computed value that depends on a service, build it in the
controller. The data layer does not reference the engine layer, and reaching for a service from
inside it is how that rule gets broken quietly.

## Endpoint checklist

1. Choose the layer: admin/management or tenant. That decides the project, the route prefix, and
   the base controller.
2. Read or write? A write needs its own role attribute even when the base already grants access.
3. Validator in the validators project, under the area.
4. DTO as a `sealed record`; mapping profile beside the other profiles.
5. Repository and service registered in the one registration extension.
6. `OkResponse` / `CreatedResponse` / `NoContentResponse`; throw for errors.
7. `[ProducesResponseType<ApiResponse<T>>(200)]` on the action.
8. Regenerate the client and commit the spec.
