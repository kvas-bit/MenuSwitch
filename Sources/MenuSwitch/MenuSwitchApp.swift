import AppKit
import Combine
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
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildMainMenu()
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
            updateStatusItemImage(button: button)
            button.toolTip = "MenuSwitch"
            button.action = #selector(togglePopover(_:))
            button.target = self
        }

        // Icon updates whenever the active profile changes (not just on needsRestart).
        viewModel.$settings
            .map { $0.selectedProfileID }
            .removeDuplicates()
            .sink { [weak self] _ in
                guard let button = self?.statusItem.button else { return }
                self?.updateStatusItemImage(button: button)
            }
            .store(in: &cancellables)
    }

    private func updateStatusItemImage(button: NSStatusBarButton) {
        let symbolName = viewModel.currentStatusBarIconName
        let composite = makeCompositeStatusBarIcon(symbolName: symbolName)
        composite.isTemplate = true
        button.image = composite
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

    private func buildMainMenu() {
        let main = NSMenu()

        let appItem = NSMenuItem()
        main.addItem(appItem)
        let appMenu = NSMenu()
        appItem.submenu = appMenu
        appMenu.addItem(withTitle: "Quit MenuSwitch", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        let editItem = NSMenuItem()
        main.addItem(editItem)
        let editMenu = NSMenu(title: "Edit")
        editItem.submenu = editMenu
        editMenu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        editMenu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        editMenu.addItem(.separator())
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")

        NSApp.mainMenu = main
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
