// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright © 2026 Jia Liu

import AppKit
import PulseCycleCore

/// Main view controller for the timer display.
final class MainViewController: NSViewController {

    // MARK: - UI Elements

    // Header
    private var workLabel: NSTextField!
    private var workTimeLabel: NSTextField!
    private var profileLabel: NSTextField!
    private var restLabel: NSTextField!
    private var restTimeLabel: NSTextField!
    private var headerView: NSView!

    // Timer area
    private var timerLabel: NSTextField!
    private var roundLabel: NSTextField!

    // Heart rate area
    private var heartRateContainer: NSView!
    private var heartRateLabel: NSTextField!
    private var connectionLabel: NSTextField!

    // Buttons
    private var startButton: NSButton!
    private var pauseButton: NSButton!
    private var resetButton: NSButton!

    // MARK: - State

    private var engine: IntervalEngine?
    private var currentProfile: WorkoutProfile { ProfileManager.shared.currentProfile }
    private let heartRateMonitor = HeartRateMonitor()
    private var isProfileListPresented = false

    // MARK: - Lifecycle

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
        view.wantsLayer = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        heartRateMonitor.delegate = self
        setupUI()
        updateUI()
    }

    // MARK: - Setup

    private func setupUI() {
        setupHeaderView()
        setupTimerArea()
        setupHeartRateArea()
        setupButtons()
    }

    private func setupHeaderView() {
        headerView = NSView()
        headerView.wantsLayer = true
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)

        // Work label and time
        workLabel = NSTextField(labelWithString: L("main.work"))
        workLabel.font = NSFont.systemFont(ofSize: 18, weight: .bold)
        workLabel.alignment = .left
        workLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(workLabel)

        workTimeLabel = NSTextField(labelWithString: "2:00")
        workTimeLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 18, weight: .bold)
        workTimeLabel.alignment = .left
        workTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(workTimeLabel)

        // Profile label with dropdown indicator
        profileLabel = NSTextField(labelWithString: "Amateur Boxing ▼")
        profileLabel.font = NSFont.systemFont(ofSize: 20, weight: .bold)
        profileLabel.alignment = .center
        profileLabel.translatesAutoresizingMaskIntoConstraints = false
        profileLabel.isSelectable = false
        profileLabel.isEditable = false
        headerView.addSubview(profileLabel)

        // Add click gesture to profile label
        let profileClick = NSClickGestureRecognizer(target: self, action: #selector(profileTapped))
        profileLabel.addGestureRecognizer(profileClick)

        // Rest label and time
        restLabel = NSTextField(labelWithString: L("main.rest"))
        restLabel.font = NSFont.systemFont(ofSize: 18, weight: .bold)
        restLabel.alignment = .right
        restLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(restLabel)

        restTimeLabel = NSTextField(labelWithString: "1:00")
        restTimeLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 18, weight: .bold)
        restTimeLabel.alignment = .right
        restTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(restTimeLabel)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 80),

            workLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 32),
            workLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 16),

            workTimeLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 32),
            workTimeLabel.topAnchor.constraint(equalTo: workLabel.bottomAnchor, constant: 4),

            profileLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            profileLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            restLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -32),
            restLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 16),

            restTimeLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -32),
            restTimeLabel.topAnchor.constraint(equalTo: restLabel.bottomAnchor, constant: 4),
        ])
    }

    private func setupTimerArea() {
        // Timer display
        timerLabel = NSTextField(labelWithString: "00:00")
        timerLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 120, weight: .bold)
        timerLabel.alignment = .center
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(timerLabel)

        // Round label
        roundLabel = NSTextField(labelWithString: "")
        roundLabel.font = NSFont.systemFont(ofSize: 24, weight: .bold)
        roundLabel.alignment = .center
        roundLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(roundLabel)

        NSLayoutConstraint.activate([
            timerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            timerLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),

            roundLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            roundLabel.topAnchor.constraint(equalTo: timerLabel.bottomAnchor, constant: 20),
        ])
    }

    private func setupHeartRateArea() {
        heartRateContainer = NSView()
        heartRateContainer.wantsLayer = true
        heartRateContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(heartRateContainer)

        heartRateLabel = NSTextField(labelWithString: "--")
        heartRateLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 100, weight: .bold)
        heartRateLabel.alignment = .center
        heartRateLabel.translatesAutoresizingMaskIntoConstraints = false
        heartRateContainer.addSubview(heartRateLabel)

        connectionLabel = NSTextField(labelWithString: L("main.heartRate.disconnected"))
        connectionLabel.font = NSFont.systemFont(ofSize: 16)
        connectionLabel.textColor = .secondaryLabelColor
        connectionLabel.alignment = .center
        connectionLabel.translatesAutoresizingMaskIntoConstraints = false
        heartRateContainer.addSubview(connectionLabel)

        // Click to connect
        let containerClick = NSClickGestureRecognizer(target: self, action: #selector(heartRateTapped))
        heartRateContainer.addGestureRecognizer(containerClick)

        NSLayoutConstraint.activate([
            heartRateContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            heartRateContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            heartRateContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            heartRateContainer.topAnchor.constraint(equalTo: roundLabel.bottomAnchor, constant: 20),

            heartRateLabel.centerXAnchor.constraint(equalTo: heartRateContainer.centerXAnchor),
            heartRateLabel.centerYAnchor.constraint(equalTo: heartRateContainer.centerYAnchor, constant: -20),

            connectionLabel.centerXAnchor.constraint(equalTo: heartRateContainer.centerXAnchor),
            connectionLabel.topAnchor.constraint(equalTo: heartRateLabel.bottomAnchor, constant: 16),
        ])
    }

    private func setupButtons() {
        startButton = NSButton(title: L("main.button.start"), target: self, action: #selector(startTapped))
        pauseButton = NSButton(title: L("main.button.pause"), target: self, action: #selector(pauseTapped))
        resetButton = NSButton(title: L("main.button.reset"), target: self, action: #selector(resetTapped))

        startButton.bezelStyle = .regularSquare
        pauseButton.bezelStyle = .regularSquare
        resetButton.bezelStyle = .regularSquare

        startButton.font = NSFont.systemFont(ofSize: 20, weight: .bold)
        pauseButton.font = NSFont.systemFont(ofSize: 20, weight: .bold)
        resetButton.font = NSFont.systemFont(ofSize: 20, weight: .bold)

        pauseButton.isEnabled = false

        let buttonStack = NSStackView(views: [resetButton, startButton, pauseButton])
        buttonStack.orientation = .horizontal
        buttonStack.spacing = 20
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        heartRateContainer.addSubview(buttonStack)

        NSLayoutConstraint.activate([
            buttonStack.centerXAnchor.constraint(equalTo: heartRateContainer.centerXAnchor),
            buttonStack.bottomAnchor.constraint(equalTo: heartRateContainer.bottomAnchor, constant: -20),
        ])
    }

    // MARK: - Actions

    @objc private func startTapped() {
        if engine == nil {
            let config = WorkoutConfig(
                warmUpSeconds: currentProfile.warmUpEnabled ? currentProfile.warmUpSeconds : 0,
                workSeconds: currentProfile.workSeconds,
                restSeconds: currentProfile.restSeconds,
                rounds: currentProfile.rounds,
                coolDownSeconds: currentProfile.coolDownEnabled ? currentProfile.coolDownSeconds : 0
            )
            engine = IntervalEngine(config: config)
            engine?.delegate = self
        }
        engine?.start()
        startButton.isEnabled = false
        pauseButton.isEnabled = true
    }

    @objc private func pauseTapped() {
        engine?.pause()
        startButton.isEnabled = true
        pauseButton.isEnabled = false
    }

    @objc private func resetTapped() {
        engine?.reset()
        engine = nil
        startButton.isEnabled = true
        pauseButton.isEnabled = false
        updateUI()
    }

    @objc private func profileTapped() {
        showProfileSelector()
    }

    @objc private func heartRateTapped() {
        heartRateMonitor.autoConnect()
    }

    private func showProfileSelector() {
        isProfileListPresented = true
        updateProfileArrow()

        let menu = NSMenu()
        let profiles = ProfileManager.shared.profiles
        let currentIndex = ProfileManager.shared.currentProfileIndex

        for (index, profile) in profiles.enumerated() {
            let item = NSMenuItem(title: profile.name, action: #selector(selectProfile(_:)), keyEquivalent: "")
            item.tag = index
            item.state = index == currentIndex ? .on : .off
            item.target = self
            menu.addItem(item)
        }

        let point = NSPoint(x: profileLabel.bounds.midX, y: profileLabel.bounds.minY - 4)
        menu.popUp(positioning: nil, at: point, in: profileLabel)

        // After menu closes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.isProfileListPresented = false
            self?.updateProfileArrow()
        }
    }

    @objc private func selectProfile(_ item: NSMenuItem) {
        ProfileManager.shared.selectProfile(at: item.tag)
        engine = nil
        updateUI()
    }

    private func updateProfileArrow() {
        let arrow = isProfileListPresented ? "▲" : "▼"
        profileLabel.stringValue = "\(currentProfile.name) \(arrow)"
    }

    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }

    // MARK: - UI Updates

    private func updateUI() {
        updateProfileArrow()
        workTimeLabel.stringValue = formatTime(currentProfile.workSeconds)
        restTimeLabel.stringValue = formatTime(currentProfile.restSeconds)

        guard let engine = engine else {
            timerLabel.stringValue = formatTime(currentProfile.workSeconds)
            roundLabel.stringValue = ""
            updateBackgroundColor(for: nil)
            return
        }

        timerLabel.stringValue = formatTime(engine.remainingSeconds)

        switch engine.phase {
        case .warmUp:
            roundLabel.stringValue = L("main.warmUp")
        case .work, .rest:
            roundLabel.stringValue = String(format: L("main.round"), engine.currentRound)
        case .coolDown:
            roundLabel.stringValue = L("main.coolDown")
        case .finished:
            roundLabel.stringValue = L("main.finished")
        }

        updateBackgroundColor(for: engine.phase)
    }

    private func updateBackgroundColor(for phase: IntervalPhase?) {
        let headerColor: NSColor
        let mainColor: NSColor
        let heartRateColor: NSColor

        if let phase = phase {
            switch phase {
            case .warmUp:
                headerColor = NSColor(hex: currentProfile.warmUpColor) ?? .controlBackgroundColor
                mainColor = headerColor
            case .work:
                headerColor = NSColor(hex: currentProfile.workColor) ?? .controlBackgroundColor
                mainColor = headerColor
            case .rest:
                headerColor = NSColor(hex: currentProfile.restColor) ?? .controlBackgroundColor
                mainColor = headerColor
            case .coolDown:
                headerColor = NSColor(hex: currentProfile.coolDownColor) ?? .controlBackgroundColor
                mainColor = headerColor
            case .finished:
                headerColor = .controlBackgroundColor
                mainColor = .controlBackgroundColor
            }
        } else {
            headerColor = NSColor(hex: currentProfile.prepareColor) ?? .controlBackgroundColor
            mainColor = headerColor
        }

        heartRateColor = NSColor(hex: currentProfile.heartRateColor) ?? NSColor(red: 1.0, green: 0.5, blue: 0.5, alpha: 0.1)

        headerView.layer?.backgroundColor = mainColor.cgColor
        view.layer?.backgroundColor = mainColor.cgColor
        heartRateContainer.layer?.backgroundColor = heartRateColor.cgColor
    }
}

// MARK: - IntervalEngineDelegate

extension MainViewController: IntervalEngineDelegate {
    func engineDidUpdateState(_ engine: IntervalEngine) {
        DispatchQueue.main.async { [weak self] in
            self?.updateUI()
        }
    }

    func engineDidTransitionToPhase(_ engine: IntervalEngine, phase: IntervalPhase) {}

    func engineDidEndPhase(_ engine: IntervalEngine, phase: IntervalPhase) {}

    func engineDidPlaySound(_ engine: IntervalEngine, sound: String) {
        DispatchQueue.main.async {
            SoundManager.shared.playSound(sound)
        }
    }

    func engineDidSpeak(_ engine: IntervalEngine, text: String) {
        DispatchQueue.main.async {
            VoiceManager.shared.speak(text)
        }
    }

    func engineDidFinish(_ engine: IntervalEngine) {
        DispatchQueue.main.async { [weak self] in
            self?.startButton.isEnabled = false
            self?.pauseButton.isEnabled = false
        }
    }
}

// MARK: - HeartRateMonitorDelegate

extension MainViewController: HeartRateMonitorDelegate {
    func heartRateMonitor(_ monitor: HeartRateMonitor, didUpdateHeartRate bpm: Int) {
        DispatchQueue.main.async { [weak self] in
            self?.heartRateLabel.stringValue = "\(bpm)"
        }
    }

    func heartRateMonitor(_ monitor: HeartRateMonitor, didChangeState state: HeartRateMonitorState) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            switch state {
            case .idle:
                self.connectionLabel.stringValue = L("main.heartRate.disconnected")
                self.heartRateLabel.stringValue = "--"
            case .scanning:
                self.connectionLabel.stringValue = L("main.heartRate.scanning")
            case .connecting:
                self.connectionLabel.stringValue = L("main.heartRate.connecting")
            case .connected:
                if let name = monitor.connectedDeviceName {
                    self.connectionLabel.stringValue = name
                }
            case .disconnected:
                self.connectionLabel.stringValue = L("main.heartRate.disconnected")
                self.heartRateLabel.stringValue = "--"
            }
        }
    }

    func heartRateMonitor(_ monitor: HeartRateMonitor, didConnectDevice name: String) {
        DispatchQueue.main.async { [weak self] in
            self?.connectionLabel.stringValue = name
        }
    }

    func heartRateMonitor(_ monitor: HeartRateMonitor, didFailWithError error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.connectionLabel.stringValue = L("main.error")
        }
    }
}
