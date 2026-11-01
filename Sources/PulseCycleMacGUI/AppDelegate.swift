// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright © 2026 Jia Liu

import AppKit
import Sparkle

/// Application delegate that shows the primary window and configures updates.
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow?
    private var settingsWindow: SettingsWindow?

    /// Standard Sparkle updater controller
    lazy var updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMainMenu()
        createMainWindow()
        configureUpdateCheck()

        // Bring the app to the foreground when launched
        NSApp.activate(ignoringOtherApps: true)
    }

    private func configureUpdateCheck() {
        updaterController.updater.automaticallyChecksForUpdates = false

        guard shouldCheckForUpdates() else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.updaterController.updater.checkForUpdatesInBackground()
            self?.recordUpdateCheck()
        }
    }

    private func shouldCheckForUpdates() -> Bool {
        let savedInterval = UserDefaults.standard.double(forKey: "settings.updateCheckInterval")

        let interval: TimeInterval
        if !UserDefaults.standard.bool(forKey: "settings.updateCheckIntervalSet") {
            interval = 604800 // Weekly default
            UserDefaults.standard.set(true, forKey: "settings.updateCheckIntervalSet")
            UserDefaults.standard.set(interval, forKey: "settings.updateCheckInterval")
        } else {
            interval = savedInterval
        }

        if interval < 0 { return false }
        if interval == 0 { return true }

        let lastCheck = UserDefaults.standard.string(forKey: "settings.lastUpdateCheck") ?? ""
        guard !lastCheck.isEmpty else { return true }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        guard let lastDate = formatter.date(from: lastCheck) else { return true }

        let now = Date()
        let timeSinceLastCheck = now.timeIntervalSince(lastDate)

        return timeSinceLastCheck >= interval
    }

    private func recordUpdateCheck() {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let now = formatter.string(from: Date())
        UserDefaults.standard.set(now, forKey: "settings.lastUpdateCheck")
    }

    private func createMainWindow() {
        // If window already exists, just bring it to front
        if let existingWindow = window {
            existingWindow.makeKeyAndOrderFront(nil)
            return
        }

        let screenFrame = NSScreen.main?.visibleFrame ?? .zero
        let width: CGFloat = 800
        let height: CGFloat = 600
        let x = screenFrame.midX - width / 2
        let y = screenFrame.midY - height / 2
        let frame = NSRect(x: x, y: y, width: width, height: height)

        let newWindow = NSWindow(
            contentRect: frame,
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )

        newWindow.title = "PulseCycle"
        newWindow.minSize = NSSize(width: 600, height: 400)
        newWindow.isReleasedWhenClosed = false
        newWindow.contentViewController = MainViewController()

        window = newWindow
        newWindow.makeKeyAndOrderFront(nil)
    }

    // MARK: - Menu Setup

    private func setupMainMenu() {
        let mainMenu = NSMenu()
        let appName = "PulseCycle"

        // App Menu
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        appMenuItem.submenu = createAppMenu(appName)

        // File Menu
        let fileMenuItem = NSMenuItem()
        mainMenu.addItem(fileMenuItem)
        fileMenuItem.submenu = createFileMenu()

        // View Menu
        let viewMenuItem = NSMenuItem()
        mainMenu.addItem(viewMenuItem)
        viewMenuItem.submenu = createViewMenu()

        // Window Menu
        let windowMenuItem = NSMenuItem()
        mainMenu.addItem(windowMenuItem)
        windowMenuItem.submenu = createWindowMenu()

        NSApp.mainMenu = mainMenu
    }

    private func createAppMenu(_ appName: String) -> NSMenu {
        let menu = NSMenu()

        let aboutItem = NSMenuItem(
            title: "About \(appName)",
            action: #selector(showAbout),
            keyEquivalent: ""
        )
        aboutItem.target = self
        menu.addItem(aboutItem)

        menu.addItem(.separator())

        let checkForUpdatesItem = NSMenuItem(
            title: "Check for Updates...",
            action: #selector(manualCheckForUpdates),
            keyEquivalent: ""
        )
        checkForUpdatesItem.target = self
        menu.addItem(checkForUpdatesItem)

        menu.addItem(.separator())

        let preferencesItem = NSMenuItem(
            title: "Settings...",
            action: #selector(showSettings),
            keyEquivalent: ","
        )
        preferencesItem.target = self
        menu.addItem(preferencesItem)

        menu.addItem(.separator())

        let hideItem = NSMenuItem(
            title: "Hide \(appName)",
            action: #selector(NSApplication.hide(_:)),
            keyEquivalent: "h"
        )
        hideItem.target = NSApp
        menu.addItem(hideItem)

        let hideOthersItem = NSMenuItem(
            title: "Hide Others",
            action: #selector(NSApplication.hideOtherApplications(_:)),
            keyEquivalent: "h"
        )
        hideOthersItem.keyEquivalentModifierMask = [.command, .option]
        hideOthersItem.target = NSApp
        menu.addItem(hideOthersItem)

        let showAllItem = NSMenuItem(
            title: "Show All",
            action: #selector(NSApplication.unhideAllApplications(_:)),
            keyEquivalent: ""
        )
        showAllItem.target = NSApp
        menu.addItem(showAllItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit \(appName)",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        quitItem.target = NSApp
        menu.addItem(quitItem)

        return menu
    }

    private func createFileMenu() -> NSMenu {
        let menu = NSMenu(title: "File")

        let closeWindowItem = NSMenuItem(
            title: "Close Window",
            action: #selector(NSWindow.performClose(_:)),
            keyEquivalent: "w"
        )
        menu.addItem(closeWindowItem)

        return menu
    }

    private func createViewMenu() -> NSMenu {
        let menu = NSMenu(title: "View")

        let enterFullScreenItem = NSMenuItem(
            title: "Enter Full Screen",
            action: #selector(NSWindow.toggleFullScreen(_:)),
            keyEquivalent: "f"
        )
        enterFullScreenItem.keyEquivalentModifierMask = [.command, .control]
        menu.addItem(enterFullScreenItem)

        return menu
    }

    private func createWindowMenu() -> NSMenu {
        let menu = NSMenu(title: "Window")

        let minimizeItem = NSMenuItem(
            title: "Minimize",
            action: #selector(NSWindow.performMiniaturize(_:)),
            keyEquivalent: "m"
        )
        menu.addItem(minimizeItem)

        let zoomItem = NSMenuItem(
            title: "Zoom",
            action: #selector(NSWindow.performZoom(_:)),
            keyEquivalent: ""
        )
        menu.addItem(zoomItem)

        menu.addItem(.separator())

        let bringAllToFrontItem = NSMenuItem(
            title: "Bring All to Front",
            action: #selector(NSApplication.arrangeInFront(_:)),
            keyEquivalent: ""
        )
        bringAllToFrontItem.target = NSApp
        menu.addItem(bringAllToFrontItem)

        return menu
    }

    // MARK: - Actions

    @objc private func showAbout() {
        NSApp.orderFrontStandardAboutPanel(nil)
    }

    @objc private func manualCheckForUpdates() {
        updaterController.updater.checkForUpdates()
    }

    @objc private func showSettings() {
        if settingsWindow == nil {
            settingsWindow = SettingsWindow()
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    // MARK: - NSApplicationDelegate

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return UserDefaults.standard.bool(forKey: "settings.quitOnClose")
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        createMainWindow()
        return true
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}
