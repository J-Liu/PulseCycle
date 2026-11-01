// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright © 2026 Jia Liu

import AppKit
import Sparkle

/// Settings window with tabs for General and About.
final class SettingsWindow: NSWindow {

    private var tabView: NSTabView!
    private var generalTab: NSView!
    private var aboutTab: NSView!
    private var languagePopup: NSPopUpButton!

    // Layout constants
    private let labelWidth: CGFloat = 140
    private let controlWidth: CGFloat = 200
    private let rowSpacing: CGFloat = 16

    init() {
        let screenFrame = NSScreen.main?.visibleFrame ?? .zero
        let width: CGFloat = 450
        let height: CGFloat = 400
        let x = screenFrame.midX - width / 2
        let y = screenFrame.midY - height / 2
        let frame = NSRect(x: x, y: y, width: width, height: height)

        super.init(
            contentRect: frame,
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )

        self.title = L("settings.title")
        self.isReleasedWhenClosed = false
        self.minSize = NSSize(width: 400, height: 300)

        setupUI()
        setupKeyHandlers()
    }

    private func setupUI() {
        tabView = NSTabView(frame: contentView!.bounds.insetBy(dx: 10, dy: 10))
        tabView.autoresizingMask = [.width, .height]

        recreateTabs()

        contentView?.addSubview(tabView)

        // Listen for language changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(languageDidChange),
            name: .languageChanged,
            object: nil
        )
    }

    private func recreateTabs() {
        // Remove existing tabs
        while let tab = tabView.tabViewItems.first {
            tabView.removeTabViewItem(tab)
        }

        generalTab = createGeneralTab()
        let generalItem = NSTabViewItem(identifier: "general")
        generalItem.label = L("settings.tab.general")
        generalItem.view = generalTab
        tabView.addTabViewItem(generalItem)

        aboutTab = createAboutTab()
        let aboutItem = NSTabViewItem(identifier: "about")
        aboutItem.label = L("settings.tab.about")
        aboutItem.view = aboutTab
        tabView.addTabViewItem(aboutItem)

        // Update window title
        self.title = L("settings.title")
    }

    @objc private func languageDidChange() {
        recreateTabs()
    }

    // MARK: - Layout Helpers

    private func wrapInTopAlignedContainer(_ stack: NSStackView) -> NSView {
        let container = NSView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor)
        ])
        return container
    }

    private func makeRow(label: String, control: NSView) -> NSStackView {
        let labelField = NSTextField(labelWithString: label)
        labelField.alignment = .right
        labelField.translatesAutoresizingMaskIntoConstraints = false
        labelField.widthAnchor.constraint(equalToConstant: labelWidth).isActive = true

        control.translatesAutoresizingMaskIntoConstraints = false

        let row = NSStackView(views: [labelField, control])
        row.orientation = .horizontal
        row.spacing = 12
        row.alignment = .centerY
        return row
    }

    private func makeVerticalStack() -> NSStackView {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = rowSpacing
        stack.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        return stack
    }

    // MARK: - General Tab

    private func createGeneralTab() -> NSView {
        let stack = makeVerticalStack()

        // Row: Language
        languagePopup = NSPopUpButton()
        for language in AppLanguage.allCases {
            languagePopup.addItem(withTitle: language.displayName)
            languagePopup.lastItem?.representedObject = language
        }
        let current = LocalizationManager.shared.currentLanguage
        if let index = AppLanguage.allCases.firstIndex(of: current) {
            languagePopup.selectItem(at: index)
        }
        languagePopup.target = self
        languagePopup.action = #selector(languageChanged(_:))
        languagePopup.widthAnchor.constraint(equalToConstant: controlWidth).isActive = true
        stack.addArrangedSubview(makeRow(label: L("settings.language"), control: languagePopup))

        // Row: Quit on close
        let quitOnCloseCheckbox = NSButton(checkboxWithTitle: L("settings.quitOnClose.checkbox"), target: self, action: #selector(quitOnCloseChanged(_:)))
        quitOnCloseCheckbox.state = UserDefaults.standard.bool(forKey: "settings.quitOnClose") ? .on : .off
        stack.addArrangedSubview(makeRow(label: L("settings.quitOnClose"), control: quitOnCloseCheckbox))

        // Row: Update check frequency
        let updateCheckPopup = NSPopUpButton()
        let frequencies: [(key: String, interval: TimeInterval)] = [
            ("settings.updateCheck.atStartup", 0),
            ("settings.updateCheck.daily", 86400),
            ("settings.updateCheck.weekly", 604800),
            ("settings.updateCheck.monthly", 2592000),
            ("settings.updateCheck.never", -1)
        ]
        for freq in frequencies {
            updateCheckPopup.addItem(withTitle: L(freq.key))
            updateCheckPopup.lastItem?.representedObject = freq.interval
        }
        // Select current value
        let savedInterval = UserDefaults.standard.double(forKey: "settings.updateCheckInterval")
        let selectedIndex: Int
        if savedInterval < 0 {
            selectedIndex = 4  // Never
        } else if savedInterval == 0 {
            selectedIndex = 0  // At startup
        } else if savedInterval <= 86400 {
            selectedIndex = 1  // Daily
        } else if savedInterval <= 604800 {
            selectedIndex = 2  // Weekly
        } else {
            selectedIndex = 3  // Monthly
        }
        updateCheckPopup.selectItem(at: selectedIndex)
        updateCheckPopup.target = self
        updateCheckPopup.action = #selector(updateCheckFrequencyChanged(_:))
        updateCheckPopup.widthAnchor.constraint(equalToConstant: controlWidth).isActive = true

        let checkNowButton = NSButton(title: L("settings.updateCheck.now"), target: self, action: #selector(checkForUpdatesNow))
        let updateCheckRow = NSStackView(views: [updateCheckPopup, checkNowButton])
        updateCheckRow.orientation = .horizontal
        updateCheckRow.spacing = 8
        stack.addArrangedSubview(makeRow(label: L("settings.updateCheck"), control: updateCheckRow))

        return wrapInTopAlignedContainer(stack)
    }

    // MARK: - About Tab

    private func createAboutTab() -> NSView {
        let container = NSView()

        let appIcon = NSImageView()
        if let icnsPath = Bundle.main.path(forResource: "PulseCycle", ofType: "icns"),
           let image = NSImage(contentsOfFile: icnsPath) {
            appIcon.image = image
        } else if let image = NSImage(named: "NSApplicationIcon") {
            appIcon.image = image
        } else {
            appIcon.image = NSImage(systemSymbolName: "timer", accessibilityDescription: nil)
            appIcon.contentTintColor = .controlAccentColor
        }
        appIcon.translatesAutoresizingMaskIntoConstraints = false
        appIcon.widthAnchor.constraint(equalToConstant: 80).isActive = true
        appIcon.heightAnchor.constraint(equalToConstant: 80).isActive = true
        container.addSubview(appIcon)

        let nameLabel = NSTextField(labelWithString: "PulseCycle")
        nameLabel.font = .systemFont(ofSize: 22, weight: .semibold)
        nameLabel.alignment = .center
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(nameLabel)

        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0"
        let versionLabel = NSTextField(labelWithString: "\(L("settings.about.version")) \(version)")
        versionLabel.alignment = .center
        versionLabel.textColor = .secondaryLabelColor
        versionLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(versionLabel)

        let copyrightLabel = NSTextField(labelWithString: L("settings.about.copyright"))
        copyrightLabel.alignment = .center
        copyrightLabel.textColor = .secondaryLabelColor
        copyrightLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(copyrightLabel)

        let githubButton = NSButton(title: "github.com/J-Liu/PulseCycle", target: self, action: #selector(openGitHub))
        githubButton.bezelStyle = .rounded
        githubButton.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(githubButton)

        let checkUpdatesButton = NSButton(title: L("menu.checkForUpdates"), target: self, action: #selector(checkForUpdatesNow))
        checkUpdatesButton.bezelStyle = .rounded
        checkUpdatesButton.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(checkUpdatesButton)

        NSLayoutConstraint.activate([
            appIcon.topAnchor.constraint(equalTo: container.topAnchor, constant: 40),
            appIcon.centerXAnchor.constraint(equalTo: container.centerXAnchor),

            nameLabel.topAnchor.constraint(equalTo: appIcon.bottomAnchor, constant: 16),
            nameLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),

            versionLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            versionLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),

            copyrightLabel.topAnchor.constraint(equalTo: versionLabel.bottomAnchor, constant: 8),
            copyrightLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),

            githubButton.topAnchor.constraint(equalTo: copyrightLabel.bottomAnchor, constant: 24),
            githubButton.centerXAnchor.constraint(equalTo: container.centerXAnchor),

            checkUpdatesButton.topAnchor.constraint(equalTo: githubButton.bottomAnchor, constant: 12),
            checkUpdatesButton.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            checkUpdatesButton.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor, constant: -20)
        ])

        return container
    }

    // MARK: - Key Handlers

    private func setupKeyHandlers() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self, self.isVisible else { return event }
            if event.keyCode == 53 { // Esc
                self.close()
                return nil
            }
            if event.modifierFlags.contains(.command) && event.keyCode == 13 { // Cmd+W
                self.close()
                return nil
            }
            return event
        }
    }

    // MARK: - Actions

    @objc private func languageChanged(_ sender: NSPopUpButton) {
        guard let selected = sender.selectedItem?.representedObject as? AppLanguage else { return }
        LocalizationManager.shared.currentLanguage = selected
    }

    @objc private func quitOnCloseChanged(_ sender: NSButton) {
        let quitOnClose = sender.state == .on
        UserDefaults.standard.set(quitOnClose, forKey: "settings.quitOnClose")
    }

    @objc private func updateCheckFrequencyChanged(_ sender: NSPopUpButton) {
        guard let interval = sender.selectedItem?.representedObject as? TimeInterval else { return }
        UserDefaults.standard.set(interval, forKey: "settings.updateCheckInterval")
    }

    @objc private func checkForUpdatesNow() {
        if let appDelegate = NSApp.delegate as? AppDelegate {
            appDelegate.updaterController.checkForUpdates(nil)
        }
    }

    @objc private func openGitHub() {
        if let url = URL(string: "https://github.com/J-Liu/PulseCycle") {
            NSWorkspace.shared.open(url)
        }
    }

    func selectTab(withIdentifier identifier: String) {
        tabView.selectTabViewItem(withIdentifier: identifier)
    }
}
