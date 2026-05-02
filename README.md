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

The helper stages `dist/MacCal.app`, copies the generated `AppIcon.icns` into the app bundle, signs it ad-hoc, and launches it.

## Package

```bash
./script/package_app.sh
./script/validate_package.sh
```

This creates:

- `dist/MacCal.app`
- `dist/MacCal-0.1.0.zip`

The packaged app uses `dist/icons/MacCal.icns` as its bundle icon. If the icon bundle does not exist yet, the package script creates it first.

The package is currently ad-hoc signed for local use. Public distribution will need Developer ID signing and notarization.

## Icons

```bash
./script/create_icon_bundle.sh
```

This creates:

- `dist/icons/MacCal-1024.png`
- `dist/icons/MacCal.iconset`
- `dist/icons/MacCal.icns`
- `dist/MacCal-icons.zip`

## Release Readiness

Before MacCal is shared outside local development, it should have:

- Developer ID signing with hardened runtime
- Notarization and stapling
- A GitHub Release with the packaged zip attached
- A quick release smoke test before uploading

## Notes

- Calendar events use Apple EventKit. Google calendars will appear if they are added to macOS Calendar.
- Holiday data uses bundled fallbacks and attempts quiet online refresh from official/government sources.
- The icon bundle is generated locally and reused by both packaging and the build/run helper.
- MacCal does not include auto-update. Releases are distributed manually through GitHub.

## Release Smoke Test

Before attaching a packaged build to a GitHub Release:

- Open MacCal from the menu bar and confirm the popover appears promptly.
- Open Options and confirm calendar permission status is shown correctly.
- Enable calendar events and confirm selected calendars can show event dots.
- Check that idle CPU is effectively zero when the popover is closed.
- Check memory use is reasonable for a small menu bar app.
