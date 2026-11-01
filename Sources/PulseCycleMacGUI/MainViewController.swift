// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright © 2026 Jia Liu

import AppKit
import PulseCycleCore

/// Main view controller for the timer display.
final class MainViewController: NSViewController {

    // MARK: - UI Elements

    private var timerLabel: NSTextField!
    private var roundLabel: NSTextField!
    private var phaseLabel: NSTextField!
    private var profileLabel: NSTextField!

    private var startButton: NSButton!
    private var pauseButton: NSButton!
    private var resetButton: NSButton!
    private var profileButton: NSButton!

    // MARK: - State

    private var engine: IntervalEngine?
    private var currentProfile: WorkoutProfile { ProfileManager.shared.currentProfile }

    // MARK: - Lifecycle

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
        view.wantsLayer = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateUI()
    }

    // MARK: - Setup

    private func setupUI() {
        // Profile label
        profileLabel = NSTextField(labelWithString: "Amateur Boxing")
        profileLabel.font = NSFont.systemFont(ofSize: 16, weight: .medium)
        profileLabel.alignment = .center
        profileLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(profileLabel)

        // Profile button
        profileButton = NSButton(title: L("main.profile.select"), target: self, action: #selector(profileTapped))
        profileButton.bezelStyle = .rounded
        profileButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(profileButton)

        // Timer display
        timerLabel = NSTextField(labelWithString: "00:00")
        timerLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 72, weight: .bold)
        timerLabel.alignment = .center
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(timerLabel)

        // Round label
        roundLabel = NSTextField(labelWithString: String(format: L("main.round"), 0))
        roundLabel.font = NSFont.systemFont(ofSize: 24, weight: .medium)
        roundLabel.alignment = .center
        roundLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(roundLabel)

        // Phase label
        phaseLabel = NSTextField(labelWithString: L("main.timer.ready"))
        phaseLabel.font = NSFont.systemFont(ofSize: 18, weight: .medium)
        phaseLabel.alignment = .center
        phaseLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(phaseLabel)

        // Buttons
        startButton = NSButton(title: L("main.button.start"), target: self, action: #selector(startTapped))
        pauseButton = NSButton(title: L("main.button.pause"), target: self, action: #selector(pauseTapped))
        resetButton = NSButton(title: L("main.button.reset"), target: self, action: #selector(resetTapped))

        startButton.bezelStyle = .rounded
        pauseButton.bezelStyle = .rounded
        resetButton.bezelStyle = .rounded
        pauseButton.isEnabled = false

        let buttonStack = NSStackView(views: [startButton, pauseButton, resetButton])
        buttonStack.orientation = .horizontal
        buttonStack.spacing = 16
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonStack)

        // Layout
        NSLayoutConstraint.activate([
            profileLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            profileLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),

            profileButton.centerYAnchor.constraint(equalTo: profileLabel.centerYAnchor),
            profileButton.leadingAnchor.constraint(equalTo: profileLabel.trailingAnchor, constant: 12),

            timerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            timerLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 30),

            roundLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            roundLabel.topAnchor.constraint(equalTo: timerLabel.bottomAnchor, constant: 16),

            phaseLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            phaseLabel.topAnchor.constraint(equalTo: roundLabel.bottomAnchor, constant: 8),

            buttonStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            buttonStack.topAnchor.constraint(equalTo: phaseLabel.bottomAnchor, constant: 32),
        ])

        // Listen for language changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(languageDidChange),
            name: .languageChanged,
            object: nil
        )
    }

    @objc private func languageDidChange() {
        updateUI()
        profileButton.title = L("main.profile.select")
        startButton.title = L("main.button.start")
        pauseButton.title = L("main.button.pause")
        resetButton.title = L("main.button.reset")
    }

    // MARK: - Actions

    @objc private func startTapped() {
        if engine == nil {
            let config = WorkoutConfig(
                warmUpSeconds: currentProfile.warmUpSeconds,
                workSeconds: currentProfile.workSeconds,
                restSeconds: currentProfile.restSeconds,
                rounds: currentProfile.rounds,
                coolDownSeconds: currentProfile.coolDownSeconds
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

    private func showProfileSelector() {
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

        let point = NSPoint(x: profileButton.bounds.minX, y: profileButton.bounds.maxY + 4)
        menu.popUp(positioning: nil, at: point, in: profileButton)
    }

    @objc private func selectProfile(_ item: NSMenuItem) {
        ProfileManager.shared.selectProfile(at: item.tag)
        engine = nil
        profileLabel.stringValue = currentProfile.name
        updateUI()
    }

    // MARK: - UI Updates

    private func updateUI() {
        profileLabel.stringValue = currentProfile.name

        guard let engine = engine else {
            timerLabel.stringValue = "00:00"
            roundLabel.stringValue = String(format: L("main.round"), 0)
            phaseLabel.stringValue = L("main.timer.ready")
            updateBackgroundColor(for: nil)
            return
        }

        let minutes = engine.remainingSeconds / 60
        let seconds = engine.remainingSeconds % 60
        timerLabel.stringValue = String(format: "%02d:%02d", minutes, seconds)

        roundLabel.stringValue = String(format: L("main.round"), engine.currentRound)

        switch engine.phase {
        case .warmUp:
            phaseLabel.stringValue = "WARM UP"
        case .work:
            phaseLabel.stringValue = L("main.timer.work")
        case .rest:
            phaseLabel.stringValue = L("main.timer.rest")
        case .coolDown:
            phaseLabel.stringValue = "COOL DOWN"
        case .finished:
            phaseLabel.stringValue = "FINISHED"
        }

        updateBackgroundColor(for: engine.phase)
    }

    private func updateBackgroundColor(for phase: IntervalPhase?) {
        let color: NSColor

        if let phase = phase {
            switch phase {
            case .warmUp:
                color = NSColor(hex: currentProfile.warmUpColor) ?? .controlBackgroundColor
            case .work:
                color = NSColor(hex: currentProfile.workColor) ?? .controlBackgroundColor
            case .rest:
                color = NSColor(hex: currentProfile.restColor) ?? .controlBackgroundColor
            case .coolDown:
                color = NSColor(hex: currentProfile.coolDownColor) ?? .controlBackgroundColor
            case .finished:
                color = .controlBackgroundColor
            }
        } else {
            color = NSColor(hex: currentProfile.prepareColor) ?? .controlBackgroundColor
        }

        view.layer?.backgroundColor = color.cgColor
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
