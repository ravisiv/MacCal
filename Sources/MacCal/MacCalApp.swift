import AppKit
import SwiftUI

@main
struct MacCalApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    init() {
        MacCalPreferences.registerDefaults()
    }

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }

    private static func shortDateString() -> String {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.calendar = .autoupdatingCurrent
        formatter.timeZone = .autoupdatingCurrent
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: Date())
    }

}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var optionsWindow: NSWindow?
    private var preferencesObserver: NSObjectProtocol?
    private var rightClickMonitor: Any?
    private var midnightTimer: Timer?
    private let popover = NSPopover()

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard SingleInstanceGuard.acquire() else {
            exit(0)
        }

        NSApp.setActivationPolicy(.accessory)

        let item = NSStatusBar.system.statusItem(withLength: 34)
        item.button?.target = self
        item.button?.action = #selector(togglePopoverAction(_:))
        item.button?.sendAction(on: [.leftMouseUp])
        statusItem = item
        updateStatusItem()
        observePreferences()
        installRightClickMonitor()
        scheduleMidnightRefresh()

        popover.behavior = .transient
        popover.animates = false
        popover.contentSize = NSSize(width: 390, height: 360)
        popover.contentViewController = NSHostingController(rootView: CalendarPopoverView())
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let preferencesObserver {
            NotificationCenter.default.removeObserver(preferencesObserver)
        }
        if let rightClickMonitor {
            NSEvent.removeMonitor(rightClickMonitor)
        }
        midnightTimer?.invalidate()
    }

    @objc private func togglePopoverAction(_ sender: Any?) {
        togglePopover(sender)
    }

    private func togglePopover(_ sender: Any?) {
        guard let button = statusItem?.button else { return }

        updateStatusItem()

        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.contentViewController = NSHostingController(rootView: CalendarPopoverView())
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    private func showControlMenu() {
        guard let button = statusItem?.button else { return }

        popover.performClose(nil)

        let menu = NSMenu()
        let optionsItem = NSMenuItem(
            title: "Options",
            action: #selector(showOptions(_:)),
            keyEquivalent: ""
        )
        optionsItem.target = self
        menu.addItem(optionsItem)
        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit(_:)), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.minY - 4), in: button)
    }

    private func installRightClickMonitor() {
        rightClickMonitor = NSEvent.addLocalMonitorForEvents(matching: [.rightMouseUp]) { [weak self] event in
            guard let self else { return event }

            if self.isEventOnStatusButton(event) {
                Task { @MainActor in
                    self.showControlMenu()
                }
                return nil
            }

            return event
        }
    }

    private func isEventOnStatusButton(_ event: NSEvent) -> Bool {
        guard let button = statusItem?.button,
              event.window == button.window else {
            return false
        }

        let point = button.convert(event.locationInWindow, from: nil)
        return button.bounds.contains(point)
    }

    @objc private func showOptions(_ sender: Any?) {
        if let optionsWindow {
            optionsWindow.makeKeyAndOrderFront(sender)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 590, height: 360),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "MacCal Options"
        window.contentViewController = NSHostingController(rootView: OptionsView())
        window.isReleasedWhenClosed = false
        window.center()
        optionsWindow = window

        window.makeKeyAndOrderFront(sender)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quit(_ sender: Any?) {
        NSApp.terminate(sender)
    }

    private static func shortDateString() -> String {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.calendar = .autoupdatingCurrent
        formatter.timeZone = .autoupdatingCurrent
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: Date())
    }

    private func observePreferences() {
        preferencesObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.updateStatusItem()
            }
        }
    }

    private func updateStatusItem() {
        guard let statusItem, let button = statusItem.button else { return }

        let format = MenuBarDisplayFormat(
            rawValue: UserDefaults.standard.string(forKey: MacCalPreferences.menuBarDisplayFormatKey)
                ?? MenuBarDisplayFormat.calendarIcon.rawValue
        ) ?? .calendarIcon
        let date = Date()

        button.toolTip = Self.shortDateString()

        switch format {
        case .calendarIcon:
            statusItem.length = 34
            button.title = ""
            button.image = CalendarMenuIcon.image(for: date)
            button.imagePosition = .imageOnly
        case .shortDate:
            statusItem.length = NSStatusItem.variableLength
            button.image = nil
            button.title = Self.shortDateString()
            button.imagePosition = .noImage
        case .dayOnly:
            statusItem.length = 24
            button.image = nil
            button.title = String(Calendar.autoupdatingCurrent.component(.day, from: date))
            button.imagePosition = .noImage
        case .weekdayDay:
            statusItem.length = NSStatusItem.variableLength
            button.image = nil
            button.title = Self.weekdayDayString(from: date)
            button.imagePosition = .noImage
        }
    }

    private func scheduleMidnightRefresh() {
        midnightTimer?.invalidate()

        let calendar = Calendar.autoupdatingCurrent
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let refreshDate = calendar.startOfDay(for: tomorrow).addingTimeInterval(1)
        let timer = Timer(fireAt: refreshDate, interval: 0, target: self, selector: #selector(refreshAfterMidnight), userInfo: nil, repeats: false)
        RunLoop.main.add(timer, forMode: .common)
        midnightTimer = timer
    }

    @objc private func refreshAfterMidnight() {
        updateStatusItem()
        popover.contentViewController = NSHostingController(rootView: CalendarPopoverView())
        scheduleMidnightRefresh()
    }

    private static func weekdayDayString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.dateFormat = "EEE d"
        return formatter.string(from: date)
    }
}

private enum CalendarMenuIcon {
    static func image(for date: Date) -> NSImage {
        let size = NSSize(width: 32, height: 25)
        let image = NSImage(size: size)
        image.lockFocus()

        let bounds = NSRect(origin: .zero, size: size)
        let bodyRect = bounds.insetBy(dx: 4, dy: 2.5)
        let bodyPath = NSBezierPath(roundedRect: bodyRect, xRadius: 5, yRadius: 5)
        NSColor.clear.setFill()
        bodyPath.fill()
        NSColor.labelColor.withAlphaComponent(0.9).setStroke()
        bodyPath.lineWidth = 1.4
        bodyPath.stroke()

        let calendar = Calendar.autoupdatingCurrent
        let day = String(calendar.component(.day, from: date))
        let weekday = weekdayString(for: date)

        let dividerY = bodyRect.maxY - 8
        let dividerPath = NSBezierPath()
        dividerPath.move(to: NSPoint(x: bodyRect.minX + 1.5, y: dividerY))
        dividerPath.line(to: NSPoint(x: bodyRect.maxX - 1.5, y: dividerY))
        NSColor.labelColor.withAlphaComponent(0.55).setStroke()
        dividerPath.lineWidth = 1
        dividerPath.stroke()

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center

        let weekdayAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 6.6, weight: .semibold),
            .foregroundColor: NSColor.labelColor.withAlphaComponent(0.85),
            .paragraphStyle: paragraph
        ]

        let dayAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: day.count == 1 ? 12.5 : 11.5, weight: .bold),
            .foregroundColor: NSColor.labelColor,
            .paragraphStyle: paragraph
        ]

        let weekdayRect = NSRect(x: bodyRect.minX, y: dividerY + 0.4, width: bodyRect.width, height: 7)
        let dayRect = NSRect(x: bodyRect.minX, y: bodyRect.minY + 0.4, width: bodyRect.width, height: 13)
        weekday.draw(in: weekdayRect, withAttributes: weekdayAttributes)
        day.draw(in: dayRect, withAttributes: dayAttributes)

        image.unlockFocus()
        image.isTemplate = false
        return image
    }

    private static func weekdayString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }
}
