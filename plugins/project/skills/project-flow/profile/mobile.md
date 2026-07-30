# Mobile

**There is no default here, and that is deliberate.** Do not infer one from the rest of this
profile.

## Why it is open

Recent mobile work went badly enough that no candidate has earned default status. It is also
genuinely unclear which mobile stack an AI agent currently works best in — the answer has been
moving, and the last attempt is not strong evidence about today.

The most recent workplace project is Flutter. It is a reference for
*what was tried*, not a statement of preference — that choice was made in a workplace context.

One thing from it does transfer regardless of framework: **that project commits to a single visual
language and enforces it as a rule**, not as a preference. Colours come from tokens and are never
hard-coded; typography comes from the theme and never from a literal size; every form field is one
of two shared input widgets, and new pages may not introduce a third. The stated goal is that a
user moving between screens feels zero discontinuity.

That discipline is worth carrying into any mobile project. Mobile surfaces fragment faster than
web ones — there are more screens, they are built at different times, and there is no shared layout
holding them together.

## What research must weigh

Beyond the usual criteria, mobile has one that decides more than it looks like it should:
**can the agent close the loop by itself** — build it, run it, see what happened, and confirm the
result without a person picking up a phone?

Concretely, and worth re-checking each time rather than assuming, because this changes:

- iOS Simulator has no camera. Anything camera-driven cannot be verified there, in any framework
  — an Apple limitation, not a framework one.
- Android emulator can be fed an image or video file as a virtual camera through its CLI. Whether
  a real barcode or QR reader actually decodes that feed is a separate question from whether the
  flag exists, and it is the question that matters.
- Agent tooling for reading the component tree — rather than looking at pixels — exists on both
  the React Native and Flutter sides and has been closing the gap between them.
- Where a surface goes native for perception rather than capability, a responsive web view is a
  legitimate candidate on testability grounds alone.

## How to decide

Prefer a measurement over an argument. Mobile decisions that hinge on "can this actually be
verified" are exactly the case for a spike: one question, an hour at most, a stated pass and fail,
and a clear statement of what each outcome decides.

Separate the acceptance test from the daily loop when weighing the answer. Testing on a real
device before shipping is fine and often planned anyway. The question that costs real time is
whether *every change during development* needs a phone in hand.
