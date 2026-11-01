// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright © 2026 Jia Liu

import AppKit
import Sparkle

/// Application delegate that shows the primary window and configures updates.
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow?

    /// Standard Sparkle updater controller
    lazy var updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )

    func applicationDidFinishLaunching(_ notification: Notification) {
        createMainWindow()
        configureUpdateCheck()

        // Bring the app to the foreground when launched
        NSApp.activate(ignoringOtherApps: true)
    }

    private func configureUpdateCheck() {
        // Disable Sparkle's built-in automatic check - we handle it ourselves
        updaterController.updater.automaticallyChecksForUpdates = false

        // Check if we should check for updates based on frequency setting
        guard shouldCheckForUpdates() else { return }

        // Delay to let the app settle
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.updaterController.updater.checkForUpdatesInBackground()
            self?.recordUpdateCheck()
        }
    }

    private func shouldCheckForUpdates() -> Bool {
        let savedInterval = UserDefaults.standard.double(forKey: "settings.updateCheckInterval")

        // Default to weekly if not set
        let interval: TimeInterval
        if !UserDefaults.standard.bool(forKey: "settings.updateCheckIntervalSet") {
            interval = 604800 // Weekly default
            UserDefaults.standard.set(true, forKey: "settings.updateCheckIntervalSet")
            UserDefaults.standard.set(interval, forKey: "settings.updateCheckInterval")
        } else {
            interval = savedInterval
        }

        // Never: don't check
        if interval < 0 { return false }

        // At startup: always check
        if interval == 0 { return true }

        // Periodic: check if enough time has passed
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
        let screenFrame = NSScreen.main?.visibleFrame ?? .zero
        let width: CGFloat = 800
        let height: CGFloat = 600
        let x = screenFrame.midX - width / 2
        let y = screenFrame.midY - height / 2
        let frame = NSRect(x: x, y: y, width: width, height: height)

        window = NSWindow(
            contentRect: frame,
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )

        window?.title = "PulseCycle"
        window?.minSize = NSSize(width: 600, height: 400)
        window?.contentViewController = MainViewController()

        window?.makeKeyAndOrderFront(nil)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return UserDefaults.standard.bool(forKey: "settings.quitOnClose")
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}
