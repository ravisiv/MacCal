import EventKit
import AppKit
import ServiceManagement
import SwiftUI

struct OptionsView: View {
    @AppStorage(MacCalPreferences.showUSHolidaysKey) private var showUSHolidays = true
    @AppStorage(MacCalPreferences.showIndiaHolidaysKey) private var showIndiaHolidays = true
    @AppStorage(MacCalPreferences.showCalendarEventsKey) private var showCalendarEvents = false
    @AppStorage(MacCalPreferences.menuBarDisplayFormatKey) private var menuBarDisplayFormat = MenuBarDisplayFormat.calendarIcon.rawValue

    @StateObject private var calendarStore = CalendarOptionsStore()
    @State private var openAtLogin = LaunchAtLoginController.isEnabled

    var body: some View {
        HStack(alignment: .top, spacing: 24) {
            VStack(alignment: .leading, spacing: 14) {
                Text("Options")
                    .font(.title2.weight(.semibold))

                coreSettings
            }
            .frame(width: 250, alignment: .topLeading)

            Divider()

            calendarManagementPane
                .frame(width: 270, alignment: .topLeading)
        }
        .padding(22)
        .frame(width: 590, height: 360)
        .onAppear {
            calendarStore.refresh()
        }
    }

    private var coreSettings: some View {
        VStack(alignment: .leading, spacing: 14) {
            settingsSection("General") {
                Toggle("Start at Login", isOn: $openAtLogin)
                    .onChange(of: openAtLogin) { _, newValue in
                        LaunchAtLoginController.setEnabled(newValue)
                        openAtLogin = LaunchAtLoginController.isEnabled
                    }
            }

            settingsSection("Display") {
                Picker("Menu bar", selection: $menuBarDisplayFormat) {
                    ForEach(MenuBarDisplayFormat.allCases) { format in
                        Text(format.title).tag(format.rawValue)
                    }
                }
                .pickerStyle(.menu)
            }

            settingsSection("Calendars") {
                Toggle("Calendar events", isOn: $showCalendarEvents)
                    .onChange(of: showCalendarEvents) { _, isEnabled in
                        if isEnabled {
                            calendarStore.requestAccess()
                        }
                    }

                Text(calendarAccessText)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if calendarStore.authorizationStatus == .denied || calendarStore.authorizationStatus == .restricted {
                    Button("Open Privacy Settings") {
                        openCalendarPrivacySettings()
                    }
                }
            }

            settingsSection("Holidays") {
                Toggle("U.S. holidays", isOn: $showUSHolidays)
                Toggle("India holidays", isOn: $showIndiaHolidays)
            }
        }
    }

    private var calendarManagementPane: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Calendar List")
                .font(.headline)

            if showCalendarEvents, calendarStore.authorizationStatus == .fullAccess {
                calendarSelectionList
            } else {
                Text("Enable Calendar events to choose which calendars appear in MacCal.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func settingsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            content()
        }
    }

    private var calendarSelectionList: some View {
        VStack(alignment: .leading, spacing: 7) {
            if calendarStore.calendarGroups.isEmpty {
                Text("No calendars found.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("\(calendarStore.selectedIDs.count) of \(calendarStore.calendars.count) calendars selected")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ScrollView {
                    VStack(alignment: .leading, spacing: 7) {
                        ForEach(calendarStore.calendarGroups) { group in
                            Toggle(isOn: Binding(
                                get: { calendarStore.isGroupSelected(group) },
                                set: { calendarStore.setSelected($0, group: group) }
                            )) {
                                HStack(spacing: 7) {
                                    calendarColorStack(group.colors)

                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(group.title)
                                            .lineLimit(1)
                                        if let subtitle = group.subtitle {
                                            Text(subtitle)
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.trailing, 8)
                }
                .frame(height: 255)
            }
        }
        .padding(.top, 2)
    }

    private func calendarColorStack(_ colors: [Color]) -> some View {
        HStack(spacing: -3) {
            ForEach(Array(colors.prefix(3).enumerated()), id: \.offset) { _, color in
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                    .overlay {
                        Circle()
                            .stroke(Color(nsColor: .windowBackgroundColor), lineWidth: 1)
                    }
            }
        }
        .frame(width: 18, alignment: .leading)
    }

    private var calendarAccessText: String {
        switch calendarStore.authorizationStatus {
        case .fullAccess:
            return "Calendar access granted."
        case .writeOnly:
            return "Calendar access is write-only; events cannot be shown."
        case .denied:
            return "Calendar access denied in System Settings."
        case .restricted:
            return "Calendar access is restricted."
        case .notDetermined:
            return showCalendarEvents ? "Calendar permission needed." : "Off until enabled."
        @unknown default:
            return "Calendar access unavailable."
        }
    }

    private func openCalendarPrivacySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars")
        if let url {
            NSWorkspace.shared.open(url)
        }
    }
}

enum LaunchAtLoginController {
    static var isEnabled: Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        }

        return false
    }

    static func toggle() {
        setEnabled(!isEnabled)
    }

    static func setEnabled(_ isEnabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if isEnabled, SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                } else if !isEnabled, SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                NSLog("MacCal launch-at-login update failed: \(error.localizedDescription)")
            }
        }
    }
}
