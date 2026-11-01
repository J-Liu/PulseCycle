// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright © 2026 Jia Liu

import AppKit
import PulseCycleCore

/// Main view controller for the timer and heart rate display.
final class MainViewController: NSViewController {

    // MARK: - UI Elements

    private var timerLabel: NSTextField!
    private var roundLabel: NSTextField!
    private var phaseLabel: NSTextField!
    private var heartRateLabel: NSTextField!
    private var connectionLabel: NSTextField!

    private var startButton: NSButton!
    private var pauseButton: NSButton!
    private var resetButton: NSButton!

    // MARK: - State

    private var engine: IntervalEngine!
    private var heartRateMonitor: HeartRateMonitor!

    // MARK: - Lifecycle

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
        view.wantsLayer = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTimerEngine()
        setupHeartRateMonitor()
    }

    // MARK: - Setup

    private func setupUI() {
        // Timer display
        timerLabel = NSTextField(labelWithString: "00:00")
        timerLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 72, weight: .bold)
        timerLabel.alignment = .center
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(timerLabel)

        // Round label
        roundLabel = NSTextField(labelWithString: "Round 0")
        roundLabel.font = NSFont.systemFont(ofSize: 24, weight: .medium)
        roundLabel.alignment = .center
        roundLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(roundLabel)

        // Phase label
        phaseLabel = NSTextField(labelWithString: "READY")
        phaseLabel.font = NSFont.systemFont(ofSize: 18, weight: .medium)
        phaseLabel.alignment = .center
        phaseLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(phaseLabel)

        // Heart rate display
        heartRateLabel = NSTextField(labelWithString: "-- BPM")
        heartRateLabel.font = NSFont.systemFont(ofSize: 36, weight: .medium)
        heartRateLabel.alignment = .center
        heartRateLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(heartRateLabel)

        // Connection status
        connectionLabel = NSTextField(labelWithString: "No Device")
        connectionLabel.font = NSFont.systemFont(ofSize: 14)
        connectionLabel.alignment = .center
        connectionLabel.textColor = .secondaryLabelColor
        connectionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(connectionLabel)

        // Buttons
        startButton = NSButton(title: "Start", target: self, action: #selector(startTapped))
        pauseButton = NSButton(title: "Pause", target: self, action: #selector(pauseTapped))
        resetButton = NSButton(title: "Reset", target: self, action: #selector(resetTapped))

        pauseButton.isEnabled = false

        let buttonStack = NSStackView(views: [startButton, pauseButton, resetButton])
        buttonStack.orientation = .horizontal
        buttonStack.spacing = 16
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonStack)

        // Layout
        NSLayoutConstraint.activate([
            timerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            timerLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 50),

            roundLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            roundLabel.topAnchor.constraint(equalTo: timerLabel.bottomAnchor, constant: 20),

            phaseLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            phaseLabel.topAnchor.constraint(equalTo: roundLabel.bottomAnchor, constant: 8),

            heartRateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            heartRateLabel.topAnchor.constraint(equalTo: phaseLabel.bottomAnchor, constant: 40),

            connectionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            connectionLabel.topAnchor.constraint(equalTo: heartRateLabel.bottomAnchor, constant: 8),

            buttonStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            buttonStack.topAnchor.constraint(equalTo: connectionLabel.bottomAnchor, constant: 32),
        ])
    }

    private func setupTimerEngine() {
        let profile = ProfileManager.shared.currentProfile
        let config = WorkoutConfig(
            warmUpSeconds: profile.warmUpSeconds,
            workSeconds: profile.workSeconds,
            restSeconds: profile.restSeconds,
            rounds: profile.rounds,
            coolDownSeconds: profile.coolDownSeconds
        )
        engine = IntervalEngine(config: config)
        engine.delegate = self
        updateUI()
    }

    private func setupHeartRateMonitor() {
        heartRateMonitor = HeartRateMonitor()
        heartRateMonitor.delegate = self
    }

    // MARK: - Actions

    @objc private func startTapped() {
        engine.start()
        startButton.isEnabled = false
        pauseButton.isEnabled = true
    }

    @objc private func pauseTapped() {
        engine.pause()
        startButton.isEnabled = true
        pauseButton.isEnabled = false
    }

    @objc private func resetTapped() {
        engine.reset()
        startButton.isEnabled = true
        pauseButton.isEnabled = false
        updateUI()
    }

    // MARK: - UI Updates

    private func updateUI() {
        let minutes = engine.remainingSeconds / 60
        let seconds = engine.remainingSeconds % 60
        timerLabel.stringValue = String(format: "%02d:%02d", minutes, seconds)

        roundLabel.stringValue = "Round \(engine.currentRound)"

        switch engine.phase {
        case .warmUp:
            phaseLabel.stringValue = "WARM UP"
        case .work:
            phaseLabel.stringValue = "WORK"
        case .rest:
            phaseLabel.stringValue = "REST"
        case .coolDown:
            phaseLabel.stringValue = "COOL DOWN"
        case .finished:
            phaseLabel.stringValue = "FINISHED"
        }
    }
}

// MARK: - IntervalEngineDelegate

extension MainViewController: IntervalEngineDelegate {
    func engineDidUpdateState(_ engine: IntervalEngine) {
        DispatchQueue.main.async { [weak self] in
            self?.updateUI()
        }
    }

    func engineDidTransitionToPhase(_ engine: IntervalEngine, phase: IntervalPhase) {
        // Phase transition handled in updateUI
    }

    func engineDidEndPhase(_ engine: IntervalEngine, phase: IntervalPhase) {
        // Phase end handled in updateUI
    }

    func engineDidPlaySound(_ engine: IntervalEngine, sound: String) {
        SoundManager.shared.playSound(sound)
    }

    func engineDidSpeak(_ engine: IntervalEngine, text: String) {
        VoiceManager.shared.speak(text)
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
            self?.heartRateLabel.stringValue = "\(bpm) BPM"
        }
    }

    func heartRateMonitor(_ monitor: HeartRateMonitor, didChangeState state: HeartRateMonitorState) {
        DispatchQueue.main.async { [weak self] in
            switch state {
            case .idle:
                self?.connectionLabel.stringValue = "Ready"
            case .scanning:
                self?.connectionLabel.stringValue = "Scanning..."
            case .connecting:
                self?.connectionLabel.stringValue = "Connecting..."
            case .connected:
                self?.heartRateLabel.stringValue = "-- BPM"
            case .disconnected:
                self?.connectionLabel.stringValue = "Disconnected"
                self?.heartRateLabel.stringValue = "-- BPM"
            }
        }
    }

    func heartRateMonitor(_ monitor: HeartRateMonitor, didFailWithError error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.connectionLabel.stringValue = "Error: \(error.localizedDescription)"
        }
    }

    func heartRateMonitor(_ monitor: HeartRateMonitor, didConnectDevice name: String) {
        DispatchQueue.main.async { [weak self] in
            self?.connectionLabel.stringValue = "Connected: \(name)"
        }
    }
}
