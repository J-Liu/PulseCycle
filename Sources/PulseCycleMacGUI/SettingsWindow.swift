// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright © 2026 Jia Liu

import AppKit

/// Settings window with general preferences.
final class SettingsWindow: NSWindow {

    private var quitOnCloseCheckbox: NSButton!

    init() {
        let screenFrame = NSScreen.main?.visibleFrame ?? .zero
        let width: CGFloat = 400
        let height: CGFloat = 200
        let x = screenFrame.midX - width / 2
        let y = screenFrame.midY - height / 2
        let frame = NSRect(x: x, y: y, width: width, height: height)

        super.init(
            contentRect: frame,
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        self.title = "Settings"
        self.isReleasedWhenClosed = false

        setupUI()
        loadSettings()
    }

    private func setupUI() {
        let contentView = self.contentView!

        // Quit on close checkbox
        quitOnCloseCheckbox = NSButton(checkboxWithTitle: "Quit when closing window", target: self, action: #selector(quitOnCloseChanged))
        quitOnCloseCheckbox.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(quitOnCloseCheckbox)

        NSLayoutConstraint.activate([
            quitOnCloseCheckbox.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            quitOnCloseCheckbox.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            quitOnCloseCheckbox.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -20),
        ])
    }

    private func loadSettings() {
        let quitOnClose = UserDefaults.standard.bool(forKey: "settings.quitOnClose")
        quitOnCloseCheckbox.state = quitOnClose ? .on : .off
    }

    @objc private func quitOnCloseChanged() {
        let quitOnClose = quitOnCloseCheckbox.state == .on
        UserDefaults.standard.set(quitOnClose, forKey: "settings.quitOnClose")
    }
}
