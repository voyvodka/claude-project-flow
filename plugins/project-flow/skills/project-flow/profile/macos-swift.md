# macOS-native (Swift)

For a tool that only ever runs on macOS and has to feel like part of the system: a menu-bar extra,
a background helper, anything using notifications, login items or Liquid Glass. Cross-platform
desktop stays [`desktop-tauri.md`](desktop-tauri.md); choose this one only when "native" is a
requirement, not a preference.

Learned from one shipped menu-bar tool. Every trap below cost that project a cycle; treat the list
as a starting point, not as complete.

## Shape

- **One SwiftPM package**, no Xcode project until something needs one (an asset catalog,
  entitlements beyond the defaults, UI tests): a UI-free library target holding the logic and the
  contract, an executable for any CLI, and the app target. Shared types mean drift between them is a
  compile error.
- **The `.app` is built by a script**: `swift build`, then a bundle with its own `Info.plist`
  (`LSUIElement` for a menu-bar-only app), ad-hoc signed, installed to `~/Applications`.
- **SwiftUI first, AppKit where SwiftUI falls short** — `MenuBarExtra` with `.window` style for a
  data-rich panel, `NSMenu` where a SwiftUI `Menu` ignores styling. Liquid Glass comes from system
  controls (toolbar items, bordered and glass button styles, segmented pickers); hand-applied glass
  in the content layer looks flat and goes against the HIG.
- **Logic is tested with `swift test`;** the UI is verified by looking at it (below).

## Traps

- **Notifications need a registered bundle.** `UNUserNotificationCenter` aborts in an unbundled
  binary, and macOS silently refuses permission to a bundle LaunchServices has not registered
  (`.build/`, `/tmp`). Guard every notification, login-item and launchd call behind an
  "is this the installed bundle" check, so the debug build can still run for UI work.
- **Every ad-hoc rebuild changes the signature.** launchd then refuses the old `SMAppService`
  registration (`EX_CONFIG`); the install script must re-register after replacing the bundle, and
  retry, because a fresh registration right after the swap can fail too.
- **Launch arguments are read only at launch.** `open App.app --args …` does nothing while the app
  is running.
- **`ImageRenderer` draws AppKit-backed controls as placeholders.** Snapshot through an off-screen
  window instead; even then a snapshot shows neither glass nor motion.
- **A background agent with `ProcessType Background` throttles every process it spawns,** and
  `DispatchQueue` timers do not count sleep: work started during a dark wake freezes and never times
  out. Decide power behaviour explicitly when the tool runs jobs.
- **SDK versus floor.** An API from a newer macOS fails to compile on a CI image with the older SDK,
  and `#available` cannot help when the symbol is missing. Pick the deployment floor and the CI image
  together.
- **UI tests cannot reach a menu-bar panel.** Plan verification around preview windows, not XCUITest.

## Verifying UI

A proxy is not a check. "Verified" for a screen means it was seen:

1. `swift build`, `swift test`.
2. A snapshot mode for layout regressions (light and dark, Increase Contrast).
3. The debug build with flags that open each surface in a normal window (`--show-…`), against a
   throwaway data root — this is where glass and motion render.
4. Capture only that window (`screencapture -l <id>`, `-v` to record motion), never the screen.
5. Motion and feel are confirmed by the owner's eyes before an increment is called done.

Install once at the end; do not quit and relaunch the installed app to test each change.

## Distribution

Ad-hoc signing is enough for one person on one Mac and needs no paid membership. Anything handed to
other people needs Developer ID signing and notarization — settle that in Phase 3, because it
changes the bundle, the signing and the CI.
