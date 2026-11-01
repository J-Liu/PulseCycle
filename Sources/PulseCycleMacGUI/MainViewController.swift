// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright © 2026 Jia Liu

import AppKit

/// Main view controller for the timer display.
final class MainViewController: NSViewController {

    // MARK: - UI Elements

    private var timerLabel: NSTextField!
    private var roundLabel: NSTextField!
    private var phaseLabel: NSTextField!

    private var startButton: NSButton!
    private var pauseButton: NSButton!
    private var resetButton: NSButton!

    // MARK: - Lifecycle

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
        view.wantsLayer = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
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

            buttonStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            buttonStack.topAnchor.constraint(equalTo: phaseLabel.bottomAnchor, constant: 32),
        ])
    }

    // MARK: - Actions

    @objc private func startTapped() {
        startButton.isEnabled = false
        pauseButton.isEnabled = true
    }

    @objc private func pauseTapped() {
        startButton.isEnabled = true
        pauseButton.isEnabled = false
    }

    @objc private func resetTapped() {
        startButton.isEnabled = true
        pauseButton.isEnabled = false
    }
}
