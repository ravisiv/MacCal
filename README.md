# MacCal

MacCal is a lightweight native macOS menu bar calendar. It opens from the menu bar, shows a roomy month calendar, highlights today, supports month/year navigation, and can show holidays and Apple Calendar events without needing a full calendar app open.

## Features

- Menu bar calendar icon with weekday and day number
- Fast popover month calendar
- Today highlight and selected-date highlight
- Previous/next month navigation
- Month picker and decade year picker
- Today button and keyboard shortcuts
- U.S. and India holiday markers
- Apple Calendar/EventKit event markers
- Calendar selection in Options
- Calendar diagnostics in Options
- Calendar-colored event dots
- Hover cards for event and holiday details
- Accessibility labels for calendar controls
- Optional launch at login
- Alternate menu bar display formats
- Right-click menu with Options and Quit

## Keyboard

- `T`: jump to today
- `←` / `→`: previous or next month
- `⌘←` / `⌘→`: previous or next year
- `↑` / `↓`: move selected date by week
- `Esc`: return to the normal month view

## Build And Run

```bash
cd /Users/ravis/Code/macclock2
swift build --disable-sandbox --cache-path ./.swiftpm-cache
./.build/arm64-apple-macosx/debug/MacCal
```

Or use the helper:

```bash
./script/build_and_run.sh
```

## Package

```bash
./script/package_app.sh
./script/validate_package.sh
```

This creates:

- `dist/MacCal.app`
- `dist/MacCal-0.1.0.zip`

The package is currently ad-hoc signed for local use. Public distribution will need Developer ID signing and notarization.

## Release Readiness

Before MacCal is shared as public software, it should have:

- Developer ID signing with hardened runtime
- Notarization and stapling
- A polished `.icns` app icon
- A clear release channel, either manual GitHub Releases or Sparkle signed auto-updates
- A quick verification pass for calendar permissions, idle CPU, memory use, and popover open latency

## Notes

- Calendar events use Apple EventKit. Google calendars will appear if they are added to macOS Calendar.
- Holiday data uses bundled fallbacks and attempts quiet online refresh from official/government sources.
- The custom app icon generation is still being polished; the app bundle may package without a custom `.icns` until that is fixed.
