# QuickDraw Level 1 PoC Verification

- Date: 2026-08-08
- Build environment: Xcode 26.3 / Swift 6.2.4 / arm64
- App: `.build/app/QuickDraw PoC.app`

## Automated evidence

| Requirement | Evidence | Result |
|---|---|---|
| Teams routes | Mute `⌘⇧M`, Camera `⌘⇧O`, Raise Hand `⌘⇧K` | Pass |
| Zoom routes | Mute `⌘⇧A`, Camera `⌘⇧V`, Raise Hand `⌥Y` | Pass |
| Meet routes | Mute `⌘D`, Camera `⌘E`, Raise Hand `⌃⌘H` on exact HTTPS `meet.google.com` | Pass |
| Expanded Action catalog | Meeting controls, reactions, Chat, Development, and Browser Actions | Pass |
| Partial capabilities | Missing Application × Action shortcut is not delivered or consumed; user override can add one | Pass |
| Application enablement | Installed targets can be excluded persistently; disabled targets pass triggers through and are omitted from the Shortcut Guide | Pass |
| Fail closed | fake Meet host, HTTP Meet, non-Meet tab, unsupported app, missing context | Pass |
| Full pipeline | routing, target revalidation, delivery, and injected failures | Pass |
| Dry Run | route is resolved without revalidation or shortcut delivery | Pass |
| Event sequence | one matching key-down/key-up pair with source marker | Pass |
| Privacy | reports retain Meet classification but not active-tab URL or non-Meet host | Pass |
| Latency guard | 1,000 in-process Dry Runs, p95 under 25 ms | Pass |
| Global Triggers | 56 unique safe Triggers monitored by CGEventTap; domain-scoped override reuse and unsupported app/page/action pass-through | Pass |
| Development applications | Expandable AI Agent / Editor / Terminal sidebar sections with scoped Actions and atomic per-application Trigger alignment; Applications remains enablement-only | Pass |
| Development navigation and editing | VS Code / Cursor / Xcode / JetBrains navigation, formatting, refactoring, editing, run, and issue mappings; VS Code region navigation | Pass |
| JetBrains mapping inheritance | Eight product identities inherit one validated macOS mapping set while retaining per-app overrides | Pass |
| Generated-event suppression | QuickDraw source marker bypasses Trigger matching | Pass |
| Shortcut conflicts | Known macOS catalog + enabled `AppleSymbolicHotKeys` best-effort detection | Pass |
| App lifecycle | Dock app and Menu Bar Extra remain available after closing the settings window | Pass |
| Native configuration window | Action-first split view, mapping inspector, Applications and Diagnostics navigation | Pass |
| Window interactions | Sidebar navigation and Inspector show/hide verified with macOS Accessibility tree | Pass |
| Language switching | Japanese / English updates live and the selection is persisted in UserDefaults | Pass |
| Shortcut Guide | QuickDraw and application-shortcut modifier holds, immediate in-place modifier switching, unassigned Trigger coverage, foreground capability filtering, persistent ON/OFF setting, preview, and release dismissal | Pass |
| Trigger configuration | Safe Trigger validation, overlapping-domain duplicate rejection, disjoint-domain reuse, dynamic HotKey registration, unassignment, default restore | Pass |
| Mapping overrides | Router uses persisted Action × Application overrides; individual and Action-level restore | Pass |
| Configuration persistence | Versioned JSON round-trip and defaults-not-copied behavior | Pass |
| Built-in Catalog | Bundled JSON decode, schema validation, complete Action/Application coverage | Pass |
| Bundle integrity | `plutil -lint`, `codesign --verify --deep --strict` | Pass |
| Formatting | `swift format lint --recursive Sources Tests Package.swift` | Pass |
| Tests | `swift test`: 82 tests, 0 failures | Pass |
| Idle resources | 43 seconds idle: CPU 0.0%, RSS about 20 MB | Pass (single observation) |

## Installed application identities

| Application | Local state | Bundle identifier |
|---|---|---|
| Google Chrome | Installed | `com.google.Chrome` |
| Zoom Workplace | Installed | `us.zoom.xos` |
| Microsoft Teams | Installed and live verified | `com.microsoft.teams2`; routes also cover legacy `com.microsoft.teams` |
| Xcode | Installed and catalog identity verified | `com.apple.dt.Xcode` |
| Android Studio | Installed and catalog identity verified | `com.google.android.studio` |
| Ghostty | Installed; default keybindings and catalog identity verified | `com.mitchellh.ghostty` |

## Permission finding

The original Carbon baseline was:

```text
QuickDraw PoC started hotkeys=F6,F7,F8 postEventAccess=false
```

The current implementation uses a modifying CGEventTap so unsupported applications can receive the original key event instead of having it swallowed by a global Carbon registration. The signed build successfully created the event tap with the existing Accessibility grant. A clean-account matrix must still confirm whether a separate Input Monitoring prompt appears on each supported macOS release.

Dry Run can validate foreground detection, browser classification, routing, and expected shortcut without Accessibility permission. Chrome tab detection can still cause an Automation prompt because it uses Apple Events.

## Manual evidence still required

### Confirmed live

- 2026-08-09: Signed CGEventTap build started with all 15 `⌘⌥` Triggers active and displayed known conflicts for `⌘⌥M/C/H/L/I` in Japanese and English.
- A physical `⌘⌥L` event was captured while Zoom was foreground; QuickDraw routed it to Captions, detected that Zoom has no mapping, and did not deliver an application shortcut.
- Non-Meet/unsupported-app passthrough and generated-event suppression are covered by policy/unit tests; physical passthrough and successful `⌘⌥M` delivery still require one manual check.

- 2026-08-09 (previous Carbon/F-key build): Zoom Workplace foreground meeting toggled mute through `Control+6 → Karabiner F6 → QuickDraw → ⌘⇧A`.
- QuickDraw recorded two successful deliveries at 9.6 ms and 4.5 ms.
- When Karabiner modifications were disabled, `Control+6` correctly did not reach QuickDraw as F6; enabling the active profile restored the route.
- 2026-08-09 (previous Carbon/F-key build): Google Meet in the active Chrome tab toggled mute through `F6 → QuickDraw → ⌘D`.
- Normal Meet deliveries completed in 17.5–37.7 ms. The first Apple Events call took 7.3 seconds and queued three repeated F6 deliveries. After adding a pressed/released gate, a controlled two-second trigger hold produced exactly one `⌘D` delivery in live verification.
- 2026-08-09 (previous Carbon/F-key build): New Microsoft Teams foreground meeting toggled mute through `F6 → QuickDraw → ⌘⇧M`.
- QuickDraw recorded eight successful Teams deliveries at 0.5–3.4 ms using bundle identifier `com.microsoft.teams2`.

The following cannot be truthfully marked verified without user permission and active meetings:

- Camera and Raise Hand live delivery in Teams, Zoom, and Meet.
- Thirty-cycle duplicate/stuck-modifier/focus-theft matrix for each target.

Follow the matrix in the root `README.md`. A delivered result appears in the menu and in Console under subsystem `dev.actionrouter.quickdraw-poc`.

For a support handoff, choose `Copy Diagnostics` from the menu. The copied text is limited to the latest 20 attempts and excludes full URLs, non-Meet hosts, tab titles, meeting codes, and captured keys.
