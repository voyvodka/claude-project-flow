# CLI Tools

**Go**, standard library first, single binary.

Established by `repostat` (July 2026) — a read-only scanner reporting the status of local git
repositories. 650 lines, two source files, **zero dependencies**: `go.mod` has no `require` block
at all.

## Why Go here

A command-line tool wants to be a file you can copy onto `PATH` and run. That rules out anything
needing a runtime present on the machine, which is most of the alternatives. Go compiles to one
static binary, starts instantly, and parallelises without ceremony.

TypeScript with Bun is the more fluent language of the two available and remains a fair choice for
something that lives inside an existing JavaScript project. For a standalone tool it loses on
distribution, and that is usually the deciding axis.

## Dependencies: genuinely zero

Not "few". The tools at this size need none, and each candidate should be argued down before it is
accepted:

- **Flag parsing** — the standard `flag` package handles a handful of options fine. A framework
  earns its place at subcommand trees, not before.
- **Colour** — ANSI escapes are three constants. Honour `NO_COLOR` and a `--no-color` flag, and
  detect a terminal with the standard library.
- **Concurrency** — a worker pool is a channel and a `WaitGroup`. Helper libraries save a few
  lines and cost a dependency.

## Shelling out beats reimplementing

The finding worth carrying forward: for a tool wrapping an existing command, **calling the real
binary usually beats a pure-Go reimplementation** — and the reason is not laziness.

Measured on real repositories, the native library was *slower* than `os/exec` plus the real tool
even before computing everything the real tool computed, pulled in fifty modules, more than tripled
the binary, and **rejected input the real tool read without complaint** — silent wrong answers on a
small fraction of repositories.

So: measure before assuming a native library is the sophisticated choice. Where the real binary is
present by definition — a git tool on a machine with git — shelling out is the correct engineering
answer, not a shortcut.

Two things that come with it, both learned the hard way:

- **Ask the command for everything in one call.** A single richer invocation beat several narrow
  ones by more than parallelism did. Process spawning dominates at this scale, so cutting process
  count matters more than adding workers — past a point, more parallelism made it *worse*.
- **Killing a process does not kill its children.** `exec.CommandContext` terminates the command it
  started; helper processes inherit the output pipe and keep the read blocked, so a timeout that
  looks correct hangs anyway. Set `cmd.WaitDelay`. This binds every network-touching call in the
  program, so it belongs in the decisions file rather than a comment.

## Verifying a read-only claim

Where a tool claims not to modify what it reads, **measure it, and prove the measurement works
first.** Snapshot the target's file tree, run several times, compare. Then run something that
*does* write and confirm the comparison catches it — a null result means nothing from an instrument
never shown to produce a positive one.

This is also where an assumption gets caught: the obvious command may write when it looks like it
reads. `git status` updates the index unless told not to.
