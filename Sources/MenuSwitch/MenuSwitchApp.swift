import AppKit
import SwiftUI

@main
struct MenuSwitchApp {
    static func main() {
        let app = NSApplication.shared
        let delegate = MenuSwitchAppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }
}

@MainActor
final class MenuSwitchAppDelegate: NSObject, NSApplicationDelegate {
    private let appSettingsStore = MenuSwitchSettingsStore()
    private let claudeStore = ClaudeCodeSettingsStore()
    private lazy var viewModel = MenuSwitchViewModel(settingsStore: appSettingsStore, claudeStore: claudeStore)
    private let popover = NSPopover()
    private var statusItem: NSStatusItem!
    private var eventMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        popover.behavior = .applicationDefined
        popover.contentSize = size(for: viewModel.page)
        popover.contentViewController = NSHostingController(
            rootView: MenuSwitchView(
                viewModel: viewModel,
                onRevealSettings: { [weak self] in self?.appSettingsStore.revealSettingsFile() },
                onRevealFolder: { [weak self] in self?.claudeStore.revealClaudeFolder() },
                onQuit: { NSApp.terminate(nil) },
                onPageChange: { [weak self] page in self?.popover.contentSize = self?.size(for: page) ?? .zero }
            )
        )

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "switch.2", accessibilityDescription: "MenuSwitch")
            button.image?.isTemplate = true
            button.toolTip = "MenuSwitch"
            button.action = #selector(togglePopover(_:))
            button.target = self
        }
    }

    @objc private func togglePopover(_ sender: Any?) {
        if popover.isShown {
            closePopover()
            return
        }

        guard let button = statusItem.button else { return }
        NSApp.activate(ignoringOtherApps: true)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()

        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.closePopover()
        }
    }

    private func closePopover() {
        popover.performClose(nil)
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    private func size(for page: MenuSwitchPage) -> NSSize {
        switch page {
        case .switcher:
            return NSSize(width: 560, height: 460)
        case .settings:
            return NSSize(width: 900, height: 700)
        }
    }
}
