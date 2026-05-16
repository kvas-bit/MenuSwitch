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
    private let settingsStore = ClaudeCodeSettingsStore()
    private lazy var viewModel = MenuSwitchViewModel(store: settingsStore)
    private let popover = NSPopover()
    private var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 980, height: 760)
        popover.contentViewController = NSHostingController(
            rootView: MenuSwitchView(
                viewModel: viewModel,
                onRevealSettings: { [weak self] in self?.settingsStore.revealSettingsFile() },
                onRevealFolder: { [weak self] in self?.settingsStore.revealClaudeFolder() },
                onQuit: { NSApp.terminate(nil) }
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
}
