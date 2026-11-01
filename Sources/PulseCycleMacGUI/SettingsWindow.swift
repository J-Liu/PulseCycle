// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright © 2026 Jia Liu

import AppKit
import Sparkle
import PulseCycleCore

/// Settings window with tabs for General, Profile, Sound, Colors, and About.
final class SettingsWindow: NSWindow {

    private var tabView: NSTabView!
    private var generalTab: NSView!
    private var profileTab: NSView!
    private var devicesTab: NSView!
    private var soundTab: NSView!
    private var colorsTab: NSView!
    private var aboutTab: NSView!
    private var languagePopup: NSPopUpButton!
    private var devicesTableView: NSTableView?

    // Layout constants
    private let labelWidth: CGFloat = 140
    private let controlWidth: CGFloat = 200
    private let rowSpacing: CGFloat = 16

    init() {
        let screenFrame = NSScreen.main?.visibleFrame ?? .zero
        let width: CGFloat = 500
        let height: CGFloat = 450
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
        self.minSize = NSSize(width: 450, height: 400)

        setupUI()
        setupKeyHandlers()
    }

    private func setupUI() {
        tabView = NSTabView(frame: contentView!.bounds.insetBy(dx: 10, dy: 10))
        tabView.autoresizingMask = [.width, .height]
        tabView.delegate = self

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

        profileTab = createProfileTab()
        let profileItem = NSTabViewItem(identifier: "profile")
        profileItem.label = L("settings.tab.profile")
        profileItem.view = profileTab
        tabView.addTabViewItem(profileItem)

        devicesTab = createDevicesTab()
        let devicesItem = NSTabViewItem(identifier: "devices")
        devicesItem.label = L("settings.tab.devices")
        devicesItem.view = devicesTab
        tabView.addTabViewItem(devicesItem)

        soundTab = createSoundTab()
        let soundItem = NSTabViewItem(identifier: "sound")
        soundItem.label = L("settings.tab.sound")
        soundItem.view = soundTab
        tabView.addTabViewItem(soundItem)

        colorsTab = createColorsTab()
        let colorsItem = NSTabViewItem(identifier: "colors")
        colorsItem.label = L("settings.tab.colors")
        colorsItem.view = colorsTab
        tabView.addTabViewItem(colorsItem)

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

    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        if minutes > 0 {
            return "\(minutes)m \(secs)s"
        }
        return "\(secs)s"
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

        // Row: Voice output
        let voiceOutputCheckbox = NSButton(checkboxWithTitle: L("settings.voiceOutput.checkbox"), target: self, action: #selector(voiceOutputChanged(_:)))
        voiceOutputCheckbox.state = ProfileManager.shared.currentProfile.voiceOutputEnabled ? .on : .off
        stack.addArrangedSubview(makeRow(label: L("settings.voiceOutput"), control: voiceOutputCheckbox))

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

    // MARK: - Profile Tab

    private func createProfileTab() -> NSView {
        let stack = makeVerticalStack()
        let profile = ProfileManager.shared.currentProfile

        // Profile name - still use text field
        let nameField = NSTextField()
        nameField.stringValue = profile.name
        nameField.placeholderString = L("settings.profileName")
        nameField.target = self
        nameField.action = #selector(profileNameChanged(_:))
        nameField.widthAnchor.constraint(equalToConstant: controlWidth).isActive = true
        stack.addArrangedSubview(makeRow(label: L("settings.profileName"), control: nameField))

        // Rounds - button to open picker
        let roundsButton = NSButton(title: "\(profile.rounds)", target: self, action: #selector(showRoundsPicker(_:)))
        roundsButton.bezelStyle = .rounded
        roundsButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
        stack.addArrangedSubview(makeRow(label: L("settings.rounds"), control: roundsButton))

        // Work time - button to open picker
        let workButton = NSButton(title: formatTime(profile.workSeconds), target: self, action: #selector(showWorkPicker(_:)))
        workButton.bezelStyle = .rounded
        workButton.widthAnchor.constraint(equalToConstant: 100).isActive = true
        stack.addArrangedSubview(makeRow(label: L("settings.work"), control: workButton))

        // Rest time - button to open picker
        let restButton = NSButton(title: formatTime(profile.restSeconds), target: self, action: #selector(showRestPicker(_:)))
        restButton.bezelStyle = .rounded
        restButton.widthAnchor.constraint(equalToConstant: 100).isActive = true
        stack.addArrangedSubview(makeRow(label: L("settings.rest"), control: restButton))

        // Prepare time - button to open picker
        let prepareButton = NSButton(title: "\(profile.prepareTime)s", target: self, action: #selector(showPreparePicker(_:)))
        prepareButton.bezelStyle = .rounded
        prepareButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
        stack.addArrangedSubview(makeRow(label: L("settings.prepareTime"), control: prepareButton))

        // Warm-up
        let warmUpCheckbox = NSButton(checkboxWithTitle: "", target: self, action: #selector(warmUpEnabledChanged(_:)))
        warmUpCheckbox.state = profile.warmUpEnabled ? .on : .off
        let warmUpButton = NSButton(title: formatTime(profile.warmUpSeconds), target: self, action: #selector(showWarmUpPicker(_:)))
        warmUpButton.bezelStyle = .rounded
        warmUpButton.widthAnchor.constraint(equalToConstant: 100).isActive = true
        warmUpButton.isEnabled = profile.warmUpEnabled
        let warmUpRow = NSStackView(views: [warmUpCheckbox, warmUpButton])
        warmUpRow.orientation = .horizontal
        warmUpRow.spacing = 8
        stack.addArrangedSubview(makeRow(label: L("settings.warmUp"), control: warmUpRow))

        // Cool-down
        let coolDownCheckbox = NSButton(checkboxWithTitle: "", target: self, action: #selector(coolDownEnabledChanged(_:)))
        coolDownCheckbox.state = profile.coolDownEnabled ? .on : .off
        let coolDownButton = NSButton(title: formatTime(profile.coolDownSeconds), target: self, action: #selector(showCoolDownPicker(_:)))
        coolDownButton.bezelStyle = .rounded
        coolDownButton.widthAnchor.constraint(equalToConstant: 100).isActive = true
        coolDownButton.isEnabled = profile.coolDownEnabled
        let coolDownRow = NSStackView(views: [coolDownCheckbox, coolDownButton])
        coolDownRow.orientation = .horizontal
        coolDownRow.spacing = 8
        stack.addArrangedSubview(makeRow(label: L("settings.coolDown"), control: coolDownRow))

        return wrapInTopAlignedContainer(stack)
    }

    // MARK: - Devices Tab

    private func createDevicesTab() -> NSView {
        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false

        // Title with add button
        let titleLabel = NSTextField(labelWithString: L("HRM Devices"))
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(titleLabel)

        let addButton = NSButton(title: "+", target: self, action: #selector(addDevice(_:)))
        addButton.font = .systemFont(ofSize: 20, weight: .bold)
        addButton.bezelStyle = .inline
        addButton.isBordered = false
        addButton.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(addButton)

        // Device list
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .bezelBorder
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(scrollView)

        let tableView = NSTableView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsMultipleSelection = false
        tableView.allowsEmptySelection = true
        tableView.tag = 100 // Device list tag
        tableView.doubleAction = #selector(deviceDoubleClicked(_:))

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("device"))
        column.width = 400
        tableView.addTableColumn(column)

        scrollView.documentView = tableView
        devicesTableView = tableView

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),

            addButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            addButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),

            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            scrollView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            scrollView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            scrollView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16),
            scrollView.heightAnchor.constraint(equalToConstant: 200)
        ])

        // Listen for device list updates
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadDeviceList),
            name: NSNotification.Name("DeviceListUpdated"),
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMonitorStateChanged),
            name: NSNotification.Name("HeartRateMonitorStateChanged"),
            object: nil
        )

        return container
    }

    @objc private func reloadDeviceList() {
        DispatchQueue.main.async { [weak self] in
            self?.devicesTableView?.reloadData()
        }
    }

    @objc private func handleMonitorStateChanged() {
        DispatchQueue.main.async { [weak self] in
            self?.devicesTableView?.reloadData()
        }
    }

    @objc private func addDevice(_ sender: NSButton) {
        let monitor = MainViewController.sharedHeartRateMonitor
        monitor.startScanning { [weak self] in
            // Timeout handler
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = L("Scan Timeout")
                alert.informativeText = L("No heart rate devices found. Please make sure your device is powered on and nearby.")
                alert.alertStyle = .informational
                alert.addButton(withTitle: L("OK"))
                alert.beginSheetModal(for: self!)
            }
        }

        let alert = NSAlert()
        alert.messageText = L("Scanning")
        alert.informativeText = L("Looking for heart rate devices...")
        alert.alertStyle = .informational
        alert.addButton(withTitle: L("Cancel"))
        alert.beginSheetModal(for: self) { response in
            if response == .alertFirstButtonReturn {
                monitor.stopScanning()
            }
        }
    }

    @objc private func deviceDoubleClicked(_ sender: NSTableView) {
        let row = sender.selectedRow
        guard row >= 0, row < DeviceManager.shared.devices.count else { return }
        let device = DeviceManager.shared.devices[row]
        let monitor = MainViewController.sharedHeartRateMonitor

        if monitor.isConnectedDevice(uuid: device.uuid) {
            monitor.disconnect()
        } else {
            monitor.connectToDevice(uuid: device.uuid)
        }
    }

    // MARK: - Sound Tab

    private func createSoundTab() -> NSView {
        let stack = makeVerticalStack()
        let profile = ProfileManager.shared.currentProfile

        // Prepare counting sound
        let prepareCountingCheckbox = NSButton(checkboxWithTitle: L("settings.sound.prepareCounting"), target: self, action: #selector(prepareCountingSoundChanged(_:)))
        prepareCountingCheckbox.state = profile.prepareCountingSoundEnabled ? .on : .off
        stack.addArrangedSubview(makeRow(label: "", control: prepareCountingCheckbox))

        // Start sound
        let startSoundCheckbox = NSButton(checkboxWithTitle: L("settings.sound.start"), target: self, action: #selector(startSoundChanged(_:)))
        startSoundCheckbox.state = profile.startSoundEnabled ? .on : .off
        stack.addArrangedSubview(makeRow(label: "", control: startSoundCheckbox))

        // Ending notify sound
        let endingNotifyCheckbox = NSButton(checkboxWithTitle: L("settings.sound.endingNotify"), target: self, action: #selector(endingNotifySoundChanged(_:)))
        endingNotifyCheckbox.state = profile.endingNotifySoundEnabled ? .on : .off
        stack.addArrangedSubview(makeRow(label: "", control: endingNotifyCheckbox))

        // End sound
        let endSoundCheckbox = NSButton(checkboxWithTitle: L("settings.sound.end"), target: self, action: #selector(endSoundChanged(_:)))
        endSoundCheckbox.state = profile.endSoundEnabled ? .on : .off
        stack.addArrangedSubview(makeRow(label: "", control: endSoundCheckbox))

        return wrapInTopAlignedContainer(stack)
    }

    // MARK: - Colors Tab

    private func createColorsTab() -> NSView {
        let stack = makeVerticalStack()
        let profile = ProfileManager.shared.currentProfile

        let colorItems: [(String, String)] = [
            (L("settings.color.work"), profile.workColor),
            (L("settings.color.rest"), profile.restColor),
            (L("settings.color.heartRate"), profile.heartRateColor),
            (L("settings.color.prepare"), profile.prepareColor),
            (L("settings.color.warmUp"), profile.warmUpColor),
            (L("settings.color.coolDown"), profile.coolDownColor)
        ]

        for (index, item) in colorItems.enumerated() {
            let colorWell = NSColorWell()
            colorWell.color = NSColor(hex: item.1) ?? .white
            colorWell.target = self
            colorWell.action = #selector(colorChanged(_:))
            colorWell.tag = index
            colorWell.widthAnchor.constraint(equalToConstant: 44).isActive = true

            let resetButton = NSButton(title: L("settings.color.reset"), target: self, action: #selector(resetColor(_:)))
            resetButton.tag = index
            resetButton.bezelStyle = .rounded

            let colorRow = NSStackView(views: [colorWell, resetButton])
            colorRow.orientation = .horizontal
            colorRow.spacing = 8
            stack.addArrangedSubview(makeRow(label: item.0, control: colorRow))
        }

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

    // MARK: - Actions - General

    @objc private func languageChanged(_ sender: NSPopUpButton) {
        guard let selected = sender.selectedItem?.representedObject as? AppLanguage else { return }
        LocalizationManager.shared.currentLanguage = selected
    }

    @objc private func quitOnCloseChanged(_ sender: NSButton) {
        let quitOnClose = sender.state == .on
        UserDefaults.standard.set(quitOnClose, forKey: "settings.quitOnClose")
    }

    @objc private func voiceOutputChanged(_ sender: NSButton) {
        var profile = ProfileManager.shared.currentProfile
        profile.voiceOutputEnabled = sender.state == .on
        ProfileManager.shared.updateProfile(profile)
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

    // MARK: - Actions - Profile

    @objc private func profileNameChanged(_ sender: NSTextField) {
        var profile = ProfileManager.shared.currentProfile
        profile.name = sender.stringValue
        ProfileManager.shared.updateProfile(profile)
        NotificationCenter.default.post(name: .profileChanged, object: nil)
    }

    // MARK: - Picker Actions

    private func showPicker(_ picker: PickerViewController) {
        let sheet = NSWindow(contentViewController: picker)
        sheet.styleMask = [.titled, .closable]
        sheet.title = picker.title ?? ""
        beginSheet(sheet) { _ in }
    }

    @objc private func showRoundsPicker(_ sender: NSButton) {
        let profile = ProfileManager.shared.currentProfile
        let picker = PickerViewController(title: L("settings.rounds"), values: Array(1...99), currentValue: profile.rounds) { [weak self] value in
            var p = ProfileManager.shared.currentProfile
            p.rounds = value
            ProfileManager.shared.updateProfile(p)
            self?.recreateTabs()
            self?.tabView.selectTabViewItem(withIdentifier: "profile")
            NotificationCenter.default.post(name: .profileChanged, object: nil)
        }
        showPicker(picker)
    }

    @objc private func showWorkPicker(_ sender: NSButton) {
        let profile = ProfileManager.shared.currentProfile
        let picker = PickerViewController(title: L("settings.work"), currentValue: profile.workSeconds, maxMinutes: 60) { [weak self] value in
            var p = ProfileManager.shared.currentProfile
            p.workSeconds = value
            ProfileManager.shared.updateProfile(p)
            self?.recreateTabs()
            self?.tabView.selectTabViewItem(withIdentifier: "profile")
            NotificationCenter.default.post(name: .profileChanged, object: nil)
        }
        showPicker(picker)
    }

    @objc private func showRestPicker(_ sender: NSButton) {
        let profile = ProfileManager.shared.currentProfile
        let picker = PickerViewController(title: L("settings.rest"), currentValue: profile.restSeconds, maxMinutes: 60) { [weak self] value in
            var p = ProfileManager.shared.currentProfile
            p.restSeconds = value
            ProfileManager.shared.updateProfile(p)
            self?.recreateTabs()
            self?.tabView.selectTabViewItem(withIdentifier: "profile")
            NotificationCenter.default.post(name: .profileChanged, object: nil)
        }
        showPicker(picker)
    }

    @objc private func showPreparePicker(_ sender: NSButton) {
        let profile = ProfileManager.shared.currentProfile
        let picker = PickerViewController(title: L("settings.prepareTime"), values: Array(0...300), currentValue: profile.prepareTime, unit: L("sec")) { [weak self] value in
            var p = ProfileManager.shared.currentProfile
            p.prepareTime = value
            ProfileManager.shared.updateProfile(p)
            self?.recreateTabs()
            self?.tabView.selectTabViewItem(withIdentifier: "profile")
            NotificationCenter.default.post(name: .profileChanged, object: nil)
        }
        showPicker(picker)
    }

    @objc private func showWarmUpPicker(_ sender: NSButton) {
        let profile = ProfileManager.shared.currentProfile
        let picker = PickerViewController(title: L("settings.warmUp"), currentValue: profile.warmUpSeconds, maxMinutes: 30) { [weak self] value in
            var p = ProfileManager.shared.currentProfile
            p.warmUpSeconds = value
            ProfileManager.shared.updateProfile(p)
            self?.recreateTabs()
            self?.tabView.selectTabViewItem(withIdentifier: "profile")
            NotificationCenter.default.post(name: .profileChanged, object: nil)
        }
        showPicker(picker)
    }

    @objc private func showCoolDownPicker(_ sender: NSButton) {
        let profile = ProfileManager.shared.currentProfile
        let picker = PickerViewController(title: L("settings.coolDown"), currentValue: profile.coolDownSeconds, maxMinutes: 30) { [weak self] value in
            var p = ProfileManager.shared.currentProfile
            p.coolDownSeconds = value
            ProfileManager.shared.updateProfile(p)
            self?.recreateTabs()
            self?.tabView.selectTabViewItem(withIdentifier: "profile")
            NotificationCenter.default.post(name: .profileChanged, object: nil)
        }
        showPicker(picker)
    }

    // MARK: - Checkbox Actions

    @objc private func warmUpEnabledChanged(_ sender: NSButton) {
        var profile = ProfileManager.shared.currentProfile
        profile.warmUpEnabled = sender.state == .on
        ProfileManager.shared.updateProfile(profile)
        recreateTabs()
        tabView.selectTabViewItem(withIdentifier: "profile")
        NotificationCenter.default.post(name: .profileChanged, object: nil)
    }

    @objc private func coolDownEnabledChanged(_ sender: NSButton) {
        var profile = ProfileManager.shared.currentProfile
        profile.coolDownEnabled = sender.state == .on
        ProfileManager.shared.updateProfile(profile)
        recreateTabs()
        tabView.selectTabViewItem(withIdentifier: "profile")
        NotificationCenter.default.post(name: .profileChanged, object: nil)
    }

    // MARK: - Actions - Sound

    @objc private func prepareCountingSoundChanged(_ sender: NSButton) {
        var profile = ProfileManager.shared.currentProfile
        profile.prepareCountingSoundEnabled = sender.state == .on
        ProfileManager.shared.updateProfile(profile)
    }

    @objc private func startSoundChanged(_ sender: NSButton) {
        var profile = ProfileManager.shared.currentProfile
        profile.startSoundEnabled = sender.state == .on
        ProfileManager.shared.updateProfile(profile)
    }

    @objc private func endingNotifySoundChanged(_ sender: NSButton) {
        var profile = ProfileManager.shared.currentProfile
        profile.endingNotifySoundEnabled = sender.state == .on
        ProfileManager.shared.updateProfile(profile)
    }

    @objc private func endSoundChanged(_ sender: NSButton) {
        var profile = ProfileManager.shared.currentProfile
        profile.endSoundEnabled = sender.state == .on
        ProfileManager.shared.updateProfile(profile)
    }

    // MARK: - Actions - Colors

    @objc private func colorChanged(_ sender: NSColorWell) {
        let hex = sender.color.toHexString()
        var profile = ProfileManager.shared.currentProfile

        switch sender.tag {
        case 0: profile.workColor = hex
        case 1: profile.restColor = hex
        case 2: profile.heartRateColor = hex
        case 3: profile.prepareColor = hex
        case 4: profile.warmUpColor = hex
        case 5: profile.coolDownColor = hex
        default: break
        }

        ProfileManager.shared.updateProfile(profile)
        NotificationCenter.default.post(name: .profileChanged, object: nil)
    }

    @objc private func resetColor(_ sender: NSButton) {
        let defaultColors = ["#FF6B6B", "#E0E0E0", "#FF8A80", "#FFAAAA", "#FF8888", "#E8A0A0"]
        var profile = ProfileManager.shared.currentProfile

        switch sender.tag {
        case 0: profile.workColor = defaultColors[0]
        case 1: profile.restColor = defaultColors[1]
        case 2: profile.heartRateColor = defaultColors[2]
        case 3: profile.prepareColor = defaultColors[3]
        case 4: profile.warmUpColor = defaultColors[4]
        case 5: profile.coolDownColor = defaultColors[5]
        default: break
        }

        ProfileManager.shared.updateProfile(profile)
        NotificationCenter.default.post(name: .profileChanged, object: nil)
        recreateTabs()
        tabView.selectTabViewItem(withIdentifier: "colors")
    }

    @objc private func openGitHub() {
        if let url = URL(string: "https://github.com/J-Liu/PulseCycle") {
            NSWorkspace.shared.open(url)
        }
    }

    func selectTab(withIdentifier identifier: String) {
        tabView.selectTabViewItem(withIdentifier: identifier)
    }

    var currentTabIdentifier: String? {
        return tabView.selectedTabViewItem?.identifier as? String
    }

    private var configTabsEnabled = true

    func setConfigTabsEnabled(_ enabled: Bool) {
        configTabsEnabled = enabled
        if !enabled {
            // Switch to About tab if currently on a config tab
            let configTabs = ["general", "profile", "sound", "colors"]
            if let current = currentTabIdentifier, configTabs.contains(current) {
                selectTab(withIdentifier: "about")
            }
        }
    }
}

// MARK: - NSTabViewDelegate

extension SettingsWindow: NSTabViewDelegate {
    func tabView(_ tabView: NSTabView, shouldSelect tabViewItem: NSTabViewItem?) -> Bool {
        guard let identifier = tabViewItem?.identifier as? String else { return true }

        // Allow About tab always, config tabs only when enabled
        if identifier == "about" {
            return true
        }
        return configTabsEnabled
    }
}

// MARK: - NSColor Extension

extension NSColor {
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }

    func toHexString() -> String {
        guard let rgbColor = usingColorSpace(.deviceRGB) else { return "#FFFFFF" }
        let r = Int(rgbColor.redComponent * 255)
        let g = Int(rgbColor.greenComponent * 255)
        let b = Int(rgbColor.blueComponent * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

// MARK: - NSTableViewDataSource & Delegate for Devices

extension SettingsWindow: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        guard tableView.tag == 100 else { return 0 }
        return DeviceManager.shared.devices.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard tableView.tag == 100, row < DeviceManager.shared.devices.count else { return nil }

        let device = DeviceManager.shared.devices[row]
        let monitor = MainViewController.sharedHeartRateMonitor
        let isConnected = monitor.isConnectedDevice(uuid: device.uuid)
        let isDefault = device.uuid == DeviceManager.shared.defaultDeviceUUID

        let cell = NSTableCellView()
        cell.translatesAutoresizingMaskIntoConstraints = false

        // Device name
        let nameField = NSTextField(labelWithString: device.name)
        nameField.font = .systemFont(ofSize: 14, weight: .medium)
        nameField.translatesAutoresizingMaskIntoConstraints = false
        cell.addSubview(nameField)

        // Status
        let statusField = NSTextField(labelWithString: "")
        statusField.font = .systemFont(ofSize: 12)
        statusField.translatesAutoresizingMaskIntoConstraints = false
        cell.addSubview(statusField)

        // Default indicator
        let defaultField = NSTextField(labelWithString: "")
        defaultField.font = .systemFont(ofSize: 12)
        defaultField.textColor = .systemGreen
        defaultField.translatesAutoresizingMaskIntoConstraints = false
        cell.addSubview(defaultField)

        NSLayoutConstraint.activate([
            nameField.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 4),
            nameField.topAnchor.constraint(equalTo: cell.topAnchor, constant: 2),

            statusField.leadingAnchor.constraint(equalTo: nameField.trailingAnchor, constant: 8),
            statusField.centerYAnchor.constraint(equalTo: nameField.centerYAnchor),

            defaultField.leadingAnchor.constraint(equalTo: statusField.trailingAnchor, constant: 8),
            defaultField.centerYAnchor.constraint(equalTo: nameField.centerYAnchor),
            defaultField.trailingAnchor.constraint(lessThanOrEqualTo: cell.trailingAnchor, constant: -4)
        ])

        if isConnected {
            statusField.stringValue = L("Connected")
            statusField.textColor = .systemGreen
        } else {
            statusField.stringValue = ""
        }

        if isDefault {
            defaultField.stringValue = "✓"
        }

        return cell
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 24
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        guard let tableView = notification.object as? NSTableView, tableView.tag == 100 else { return }
        let row = tableView.selectedRow
        guard row >= 0, row < DeviceManager.shared.devices.count else { return }

        // Deselect to allow action sheet
        tableView.deselectAll(nil)

        let device = DeviceManager.shared.devices[row]
        let monitor = MainViewController.sharedHeartRateMonitor
        let isConnected = monitor.isConnectedDevice(uuid: device.uuid)
        let isDefault = device.uuid == DeviceManager.shared.defaultDeviceUUID

        let alert = NSAlert()
        alert.messageText = device.name

        // Add buttons based on state
        if !isConnected {
            alert.addButton(withTitle: L("Connect"))
        } else {
            alert.addButton(withTitle: L("Disconnect"))
        }

        if !isDefault {
            alert.addButton(withTitle: L("Set as Default"))
        }

        alert.addButton(withTitle: L("Remove"))
        alert.addButton(withTitle: L("Cancel"))
        alert.alertStyle = .informational

        alert.beginSheetModal(for: self) { [weak self] response in
            switch response {
            case .alertFirstButtonReturn:
                if isConnected {
                    monitor.disconnect()
                } else {
                    monitor.connectToDevice(uuid: device.uuid)
                }
            case .alertSecondButtonReturn:
                if isConnected {
                    // This was Remove button
                    monitor.disconnect()
                    if let index = DeviceManager.shared.devices.firstIndex(where: { $0.uuid == device.uuid }) {
                        DeviceManager.shared.removeDevice(at: index)
                    }
                } else {
                    // This was Set as Default button
                    DeviceManager.shared.setDefaultDevice(uuid: device.uuid)
                }
            case .alertThirdButtonReturn:
                if !isDefault {
                    // This was Remove button
                    if isConnected {
                        monitor.disconnect()
                    }
                    if let index = DeviceManager.shared.devices.firstIndex(where: { $0.uuid == device.uuid }) {
                        DeviceManager.shared.removeDevice(at: index)
                    }
                }
            default:
                break
            }
            self?.devicesTableView?.reloadData()
        }
    }
}
