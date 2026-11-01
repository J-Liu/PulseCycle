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

    // Timer container (upper 65%)
    private var timerContainer: NSView!
    private var timerLabel: NSTextField!
    private var roundLabel: NSTextField!
    private var buttonsView: NSView!
    private var goButton: NSButton!
    private var resetButton: NSButton!

    // Heart rate container (lower 35%)
    private var heartRateContainer: NSView!
    private var heartRateLabel: NSTextField!
    private var connectionLabel: NSTextField!

    // MARK: - State

    private var engine: IntervalEngine?
    private var currentProfile: WorkoutProfile { ProfileManager.shared.currentProfile }
    private let heartRateMonitor = HeartRateMonitor()
    private var isProfileListPresented = false
    private var isRunning = false
    private var hasReset = true

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
        setupTimerContainer()
        setupHeaderView()
        setupTimerArea()
        setupButtons()
        setupHeartRateArea()
    }

    private func setupTimerContainer() {
        timerContainer = NSView()
        timerContainer.wantsLayer = true
        timerContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(timerContainer)

        NSLayoutConstraint.activate([
            timerContainer.topAnchor.constraint(equalTo: view.topAnchor),
            timerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            timerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            timerContainer.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.65),
        ])
    }

    private func setupHeaderView() {
        headerView = NSView()
        headerView.wantsLayer = true
        headerView.translatesAutoresizingMaskIntoConstraints = false
        timerContainer.addSubview(headerView)

        // Work label and time
        workLabel = NSTextField(labelWithString: L("main.work"))
        workLabel.font = NSFont.systemFont(ofSize: 20, weight: .bold)
        workLabel.alignment = .left
        workLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(workLabel)

        workTimeLabel = NSTextField(labelWithString: "2:00")
        workTimeLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 20, weight: .bold)
        workTimeLabel.alignment = .left
        workTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(workTimeLabel)

        // Profile label with dropdown indicator
        profileLabel = NSTextField(labelWithString: "Amateur Boxing ▼")
        profileLabel.font = NSFont.systemFont(ofSize: 22, weight: .bold)
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
        restLabel.font = NSFont.systemFont(ofSize: 20, weight: .bold)
        restLabel.alignment = .right
        restLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(restLabel)

        restTimeLabel = NSTextField(labelWithString: "1:00")
        restTimeLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 20, weight: .bold)
        restTimeLabel.alignment = .right
        restTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(restTimeLabel)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: timerContainer.topAnchor, constant: 48),
            headerView.leadingAnchor.constraint(equalTo: timerContainer.leadingAnchor, constant: 32),
            headerView.trailingAnchor.constraint(equalTo: timerContainer.trailingAnchor, constant: -32),
            headerView.heightAnchor.constraint(equalToConstant: 60),

            workLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            workLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 8),

            workTimeLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            workTimeLabel.topAnchor.constraint(equalTo: workLabel.bottomAnchor, constant: 4),

            profileLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            profileLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            restLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            restLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 8),

            restTimeLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            restTimeLabel.topAnchor.constraint(equalTo: restLabel.bottomAnchor, constant: 4),
        ])
    }

    private func setupTimerArea() {
        // Timer display
        timerLabel = NSTextField(labelWithString: "00:00")
        timerLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 140, weight: .bold)
        timerLabel.alignment = .center
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        timerContainer.addSubview(timerLabel)

        // Round label
        roundLabel = NSTextField(labelWithString: "")
        roundLabel.font = NSFont.systemFont(ofSize: 24, weight: .bold)
        roundLabel.alignment = .center
        roundLabel.translatesAutoresizingMaskIntoConstraints = false
        timerContainer.addSubview(roundLabel)

        NSLayoutConstraint.activate([
            timerLabel.centerXAnchor.constraint(equalTo: timerContainer.centerXAnchor),
            timerLabel.centerYAnchor.constraint(equalTo: timerContainer.centerYAnchor, constant: -20),
            timerLabel.leadingAnchor.constraint(lessThanOrEqualTo: timerContainer.leadingAnchor, constant: 16),
            timerLabel.trailingAnchor.constraint(lessThanOrEqualTo: timerContainer.trailingAnchor, constant: -16),

            roundLabel.centerXAnchor.constraint(equalTo: timerContainer.centerXAnchor),
            roundLabel.topAnchor.constraint(equalTo: timerLabel.bottomAnchor, constant: 20),
        ])
    }

    private func setupButtons() {
        buttonsView = NSView()
        buttonsView.translatesAutoresizingMaskIntoConstraints = false
        timerContainer.addSubview(buttonsView)

        // Go button - larger, red background, white text, white border
        goButton = NSButton(title: L("main.button.go"), target: self, action: #selector(goTapped))
        goButton.bezelStyle = .regularSquare
        goButton.font = NSFont.systemFont(ofSize: 28, weight: .bold)
        goButton.contentTintColor = .white
        goButton.wantsLayer = true
        goButton.layer?.backgroundColor = NSColor.systemRed.cgColor
        goButton.layer?.cornerRadius = 12
        goButton.layer?.borderWidth = 2
        goButton.layer?.borderColor = NSColor.white.cgColor
        goButton.translatesAutoresizingMaskIntoConstraints = false
        buttonsView.addSubview(goButton)

        // Reset button - smaller
        resetButton = NSButton(title: L("main.button.reset"), target: self, action: #selector(resetTapped))
        resetButton.bezelStyle = .regularSquare
        resetButton.font = NSFont.systemFont(ofSize: 20, weight: .bold)
        resetButton.contentTintColor = .white
        resetButton.wantsLayer = true
        resetButton.layer?.backgroundColor = NSColor.systemRed.cgColor
        resetButton.layer?.cornerRadius = 10
        resetButton.layer?.borderWidth = 2
        resetButton.layer?.borderColor = NSColor.white.cgColor
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        buttonsView.addSubview(resetButton)

        NSLayoutConstraint.activate([
            buttonsView.leadingAnchor.constraint(equalTo: timerContainer.leadingAnchor),
            buttonsView.trailingAnchor.constraint(equalTo: timerContainer.trailingAnchor),
            buttonsView.bottomAnchor.constraint(equalTo: timerContainer.bottomAnchor),
            buttonsView.heightAnchor.constraint(equalToConstant: 120),

            goButton.centerXAnchor.constraint(equalTo: buttonsView.centerXAnchor),
            goButton.topAnchor.constraint(equalTo: buttonsView.topAnchor, constant: 12),
            goButton.widthAnchor.constraint(equalToConstant: 140),
            goButton.heightAnchor.constraint(equalToConstant: 56),

            resetButton.trailingAnchor.constraint(equalTo: buttonsView.trailingAnchor, constant: -24),
            resetButton.centerYAnchor.constraint(equalTo: goButton.centerYAnchor),
            resetButton.widthAnchor.constraint(equalToConstant: 100),
            resetButton.heightAnchor.constraint(equalToConstant: 48),
        ])
    }

    private func setupHeartRateArea() {
        heartRateContainer = NSView()
        heartRateContainer.wantsLayer = true
        heartRateContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(heartRateContainer)

        heartRateLabel = NSTextField(labelWithString: "--")
        heartRateLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 140, weight: .bold)
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
            heartRateContainer.topAnchor.constraint(equalTo: timerContainer.bottomAnchor),
            heartRateContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            heartRateContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            heartRateContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            heartRateLabel.centerXAnchor.constraint(equalTo: heartRateContainer.centerXAnchor),
            heartRateLabel.centerYAnchor.constraint(equalTo: heartRateContainer.centerYAnchor, constant: -20),

            connectionLabel.centerXAnchor.constraint(equalTo: heartRateContainer.centerXAnchor),
            connectionLabel.topAnchor.constraint(equalTo: heartRateLabel.bottomAnchor, constant: 16),
        ])
    }

    // MARK: - Actions

    @objc private func goTapped() {
        // If workout finished, reset and start
        if engine?.phase == .finished {
            resetTapped()
        }

        if isRunning {
            engine?.pause()
            isRunning = false
        } else {
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
            isRunning = true
            hasReset = false
        }
        updateGoButton()
    }

    @objc private func resetTapped() {
        engine?.reset()
        engine = nil
        isRunning = false
        hasReset = true
        updateUI()
        updateGoButton()
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

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.isProfileListPresented = false
            self?.updateProfileArrow()
        }
    }

    @objc private func selectProfile(_ item: NSMenuItem) {
        ProfileManager.shared.selectProfile(at: item.tag)
        engine = nil
        isRunning = false
        hasReset = true
        updateUI()
        updateGoButton()
    }

    private func updateProfileArrow() {
        let arrow = isProfileListPresented ? "▲" : "▼"
        profileLabel.stringValue = "\(currentProfile.name) \(arrow)"
    }

    private func updateGoButton() {
        if isRunning {
            goButton.title = L("main.button.pause")
        } else if engine?.phase == .finished {
            goButton.title = L("main.button.go")
        } else if hasReset {
            goButton.title = L("main.button.go")
        } else {
            goButton.title = L("main.button.resume")
        }
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
        let timerColor: NSColor

        if let phase = phase {
            switch phase {
            case .warmUp:
                timerColor = NSColor(hex: currentProfile.warmUpColor) ?? .controlBackgroundColor
            case .work:
                timerColor = NSColor(hex: currentProfile.workColor) ?? .controlBackgroundColor
            case .rest:
                timerColor = NSColor(hex: currentProfile.restColor) ?? .controlBackgroundColor
            case .coolDown:
                timerColor = NSColor(hex: currentProfile.coolDownColor) ?? .controlBackgroundColor
            case .finished:
                timerColor = .controlBackgroundColor
            }
        } else {
            timerColor = NSColor(hex: currentProfile.prepareColor) ?? .controlBackgroundColor
        }

        let heartRateColor = NSColor(hex: currentProfile.heartRateColor) ?? NSColor(red: 1.0, green: 0.5, blue: 0.5, alpha: 0.1)

        headerView.layer?.backgroundColor = timerColor.cgColor
        timerContainer.layer?.backgroundColor = timerColor.cgColor
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
            self?.isRunning = false
            self?.updateUI()
            self?.updateGoButton()
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
