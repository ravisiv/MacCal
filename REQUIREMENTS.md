# MacCal Requirements

## Product Goal

Build MacCal, a native macOS menu bar calendar app that opens instantly from the top menu bar and shows a clean, readable month calendar. The app is intended as a faster, simpler replacement for the built-in macOS calendar/notification widget when the user only wants to quickly inspect dates.

## Core Requirements

- The app must run as a menu bar app, with an icon or date indicator in the macOS menu bar.
- The app must behave as a singleton; only one MacCal instance should run at a time.
- The menu bar item must show only the current date using the system short-date format.
- The menu bar item should look like a compact monochrome outline calendar icon that displays the weekday and today's day number.
- Clicking the menu bar item must open a calendar popover.
- Right-clicking the menu bar item must show a control menu with only Options and Quit.
- The Options menu item must open an options window.
- The options window must include a Start at Login checkbox.
- The options window must include holiday visibility checkboxes for India and U.S. holidays.
- The right-click control menu must include Quit.
- The popover must show the current month by default.
- The calendar must be a comfortable, readable size, similar in spirit to the Windows calendar shown when clicking the clock.
- Today's date must be clearly highlighted.
- A clicked date must become visually selected.
- Today's date and the selected date must use different visual treatments.
- The user must be able to navigate to the previous month.
- The user must be able to navigate to the next month.
- Previous and next month controls should sit near the vertical middle of the calendar panel sides for easier reach.
- Previous and next month controls must stay visually anchored and must not jump when switching between shorter and longer months.
- The app must include a Today button that returns the visible month and selected date to today.
- The user must be able to click or otherwise enter a year-selection mode.
- Year selection must allow choosing years beyond only the current adjacent years.
- Year selection must be presented as a grid.
- The year grid must show one decade at a time.
- The app must launch automatically at login.
- The user must be able to turn launch-at-login on or off from the Options window.
- The app must support both light and dark appearances.
- The app must follow the system appearance by default.
- The app must feel simple and focused: viewing a month calendar should be the primary experience.
- The app must show U.S. holidays and Indian holidays.
- The app should support showing events from Apple Calendar.
- The app should support showing Google Calendar events.
- Calendar event display should be optional and controlled from Options.
- Calendar event access must require explicit user permission.
- Dates with events should have a subtle event indicator distinct from holiday markers.
- Hovering over a date with events should show a compact hover card near that date.
- The event hover card should be the primary event display; the calendar should not show event details in a persistent bottom area by default.
- The event hover card should show event time and title.
- The event hover card should show only the first few events and then a `+N more` line when the date has more events.
- If a date has both events and holidays, the hover card should show events first, then a separator, then holidays.
- A future version may optionally pin date details at the bottom after clicking a date, but hover should remain the default lightweight inspection behavior.
- Holidays must be highlighted with a visual treatment that is distinct from today and selected dates.
- Hovering over a holiday date must show the holiday name.
- Moving the pointer away from a holiday date must hide the holiday name.
- Holiday data should be refreshed from official online sources when internet access is available.
- If holiday data cannot be refreshed, the app must fall back to a bundled list of well-known holidays.

## Performance Requirements

- The app must open the popover very quickly after the menu bar item is clicked.
- The app must have a very low memory footprint.
- The app must have a very low CPU footprint while idle.
- The app should define and track a lightweight performance budget: effectively zero idle CPU, scoped visible-range calendar fetches, and a popover that appears without noticeable delay.
- The app should avoid background polling unless absolutely necessary.
- The calendar view should be lightweight and render using native macOS UI where practical.
- Date calculations should be simple, deterministic, and cached or recomputed only when needed.

## UX Requirements

- The popover should appear anchored to the menu bar item.
- The current month view should be immediately visible without extra clicks.
- The initial popover size should be roomy and comparable to the Windows clock calendar, then adjusted after visual review.
- The calendar should avoid excessive empty bottom padding; the popover height should closely fit the calendar content.
- Month navigation controls should be obvious and easy to hit.
- The current month and year should be visible.
- Clicking the month/year header should expose broader month or year navigation.
- The app should dismiss naturally when the user clicks outside the popover.
- The app should provide an obvious way to quit without using Activity Monitor or Terminal.
- The interface should feel native to macOS while avoiding the current macOS widget behavior the user dislikes.
- The first day of the week must follow the user's macOS system locale settings.
- Holiday highlighting should remain subtle enough that the calendar is still easy to scan.
- Dates with multiple holidays must be able to show more than one holiday name.
- The app should clearly distinguish U.S. holidays from Indian holidays when a date is inspected.
- The app should let users hide either U.S. or India holiday markers from the Options window.
- The Options window should include calendar event toggles.
- Calendar event markers should not visually overpower today, selected date, or holiday indicators.
- Calendar event details should not cause the popover layout to jump while hovering between dates.
- The Options window should use a clear Settings-style layout with sections for General, Display, Calendars, and Holidays.
- If calendar permission is denied or restricted, Options should provide a way to open the relevant macOS privacy settings.
- The app should let the user choose which Apple/EventKit calendars to display.
- Event dots should reflect the source calendar color when possible.
- Event hover text should include enough context to identify the event without cluttering the calendar.
- Jumping back to today should clear stale hover state and return to the normal month view.
- The menu bar icon/date should refresh automatically after midnight.
- Debug or development builds must not repeatedly add duplicate login items.
- If calendar events are enabled but no calendars or visible events are available, Options should show a concise status.
- Options should show calendar diagnostics including permission state, calendar count, selected calendar count, last refresh time, and recent EventKit errors when available.
- Calendar selection should group duplicate calendar names cleanly and make the source/account context understandable when possible.
- Calendar selection should include Select All and Select None controls.
- The app should preserve the original low-footprint goal: idle CPU should remain effectively zero, and calendar/event fetches should be scoped to visible ranges.
- Before packaging, the app should have stable identity metadata: bundle identifier, version, category, usage descriptions, entitlements, and app icon.
- If calendar permission is denied or unavailable, the app should fail quietly and continue showing the date calendar and holidays.
- Hover detail cards must stay within the popover bounds near left/right/top/bottom edges.
- The calendar UI should include useful accessibility labels for day cells, navigation controls, and options controls.
- The Options window should avoid layout jumps when calendar event settings are toggled.
- The app should include focused tests for date grid generation, start-of-week behavior, today reset assumptions, holiday/event deduping, and month/year navigation logic.

## Calendar Event Requirements

- Apple Calendar integration should use EventKit.
- The app should request full calendar access only when the user enables calendar event display.
- The app must include the required calendar usage description in its app metadata.
- Sandboxed macOS builds must include the calendar personal-information entitlement.
- Event fetching should query only the visible date range, such as the current visible month grid.
- Event data should be cached lightly in memory and refreshed when the visible month changes or when the system calendar database changes.
- Google Calendar should initially be supported through macOS Calendar accounts when possible, because EventKit can surface Google calendars that the user has added to Apple Calendar.
- Direct Google Calendar API integration should be a later optional integration for users who do not want to add their Google account to macOS Calendar.
- Direct Google Calendar API integration must use OAuth and the narrowest reasonable read-only scope.
- Direct Google Calendar API requests should use time-bounded event queries for the visible calendar range and should avoid polling in the background.
- The popover should support a keyboard shortcut to jump back to today.
- The app should support a month picker so the user can choose a month directly.
- The app should support the existing decade-based year picker for broad year navigation.
- Right-clicking a date inside the calendar should offer a Copy Date action.
- The popover should support keyboard navigation.
- Left and right arrow keys should move to the previous and next month.
- Command-left and Command-right should move to the previous and next year.
- The Options window should include alternate menu bar display formats.
- Holiday hover text should appear close to the hovered date when practical, rather than only as distant static text.
- The menu bar calendar icon should be polished enough to feel native on macOS in both light and dark menu bars.
- The menu bar calendar icon should avoid bright colors and use a quiet monochrome treatment.
- Week numbers should be available as an optional setting in a future version, off by default.
- Holiday data should auto-refresh and fail quietly; the app should not interrupt the user when online refresh fails.
- The app should eventually be packaged as a proper `.app` for reliable launch-at-login and use without Terminal.

## Holiday Data Requirements

- U.S. holiday data should come from the U.S. Office of Personnel Management federal holidays page where practical: `https://www.opm.gov/policy-data-oversight/pay-leave/federal-holidays/`.
- Indian holiday data should come from the National Portal of India holiday calendar where practical: `https://www.india.gov.in/calendar`.
- India Post's official all-India holidays page can be used as a government fallback source for Indian all-India holidays: `https://www.indiapost.gov.in/holidays-list`.
- Online holiday refresh should be cached locally so the app does not fetch data every time the popover opens.
- The app should refresh holiday data infrequently, such as once per day or once per week, to preserve the low CPU and network footprint.
- The app should handle failed network requests silently and continue showing bundled fallback holidays.
- Holiday source metadata should be stored with cached holiday data so the app can show or debug where the data came from.
- Holiday refresh should happen automatically; the user should not need to manually refresh holiday data in normal use.

## Packaging, Signing, and Update Requirements

- Local packaging should continue to produce a usable `.app` and zip artifact.
- Public distribution should use Developer ID signing, hardened runtime, notarization, and stapling before sharing outside the developer's machine.
- Packaging validation should check bundle metadata, entitlements, code signature status, and archive output.
- The app should use the generated polished `.icns` app icon from the local icon bundle.
- Distribution should be through manual GitHub Releases with the packaged zip attached.
- The app should not include an auto-update feature for now.

## Initial Assumptions

- The first version will be a native Swift/SwiftUI macOS app.
- The app name will be MacCal.
- The app will support the current macOS version on the user's Mac and newer versions.
- The app will be menu-bar-only by default, without a Dock icon.
- The popover will use `NSPopover` or a SwiftUI view hosted inside an AppKit menu bar controller for fast display and native behavior.
- The app will not require calendar account access in the first version.
- The app will not show events in the first version unless requested later.
- The week layout will use the user's current locale/calendar settings by default.
- Today highlighting will use the user's local timezone.
- The app will prioritize speed and low resource usage over advanced calendar features.
- The initial menu bar display will show a compact calendar icon with weekday and day number.
- Date clicks will only update visual selection in the first version.
- The year picker will show a decade at a time.
- Launch at login will be enabled by default.

## Open Questions

- Do you want event display later, or should this stay strictly date-only?
- Should the app support keyboard navigation, such as arrow keys and Escape?

## Nice-to-Have Future Features

- Week numbers.
- Proper `.app` packaging.
- Optional event integration if the user grants calendar permissions.
