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

    func applicationDidFinishLaunching(_ notification: Notification) {
        popover.behavior = .transient
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
            popover.performClose(sender)
            return
        }

        guard let button = statusItem.button else { return }
        NSApp.activate(ignoringOtherApps: true)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    private func size(for page: MenuSwitchPage) -> NSSize {
        switch page {
        case .switcher:
            return NSSize(width: 680, height: 460)
        case .settings:
            return NSSize(width: 1120, height: 780)
        }
    }
}
