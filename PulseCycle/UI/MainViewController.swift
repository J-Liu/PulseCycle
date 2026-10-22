// SPDX-FileCopyrightText: 2026 Jia Liu
// SPDX-License-Identifier: Apache-2.0

import UIKit

class MainViewController: UIViewController, IntervalEngineDelegate, HeartRateMonitorDelegate {
    private let phaseLabel = UILabel()
    private let timeLabel = UILabel()
    private let roundLabel = UILabel()
    private let heartRateLabel = UILabel()
    private let bpmLabel = UILabel()
    private let connectionLabel = UILabel()

    private let engine: IntervalEngine
    private let heartRateMonitor: HeartRateMonitor
    private var backgroundTimestamp: Date?

    init() {
        let config = WorkoutConfig(
            warmUpSeconds: 60,
            workSeconds: 30,
            restSeconds: 15,
            rounds: 8,
            coolDownSeconds: 60
        )
        engine = IntervalEngine(config: config)
        heartRateMonitor = HeartRateMonitor()
        super.init(nibName: nil, bundle: nil)
        engine.delegate = self
        heartRateMonitor.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupGestures()
        updateUI()
        heartRateMonitor.startScanning()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleResignActive),
            name: UIScene.willDeactivateNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleEnterForeground),
            name: UIScene.willEnterForegroundNotification,
            object: nil
        )
    }

    private func setupGestures() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        view.addGestureRecognizer(tap)

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        view.addGestureRecognizer(longPress)
    }

    @objc private func handleTap() {
        if engine.phase == .finished {
            engine.reset()
            updateUI()
        } else {
            engine.start()
        }
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        engine.reset()
        updateUI()
    }

    @objc private func handleResignActive() {
        backgroundTimestamp = Date()
        engine.pause()
    }

    @objc private func handleEnterForeground() {
        guard let timestamp = backgroundTimestamp else { return }
        let elapsed = Int(Date().timeIntervalSince(timestamp))
        backgroundTimestamp = nil

        if elapsed > 0 && engine.phase != .finished {
            for _ in 0..<elapsed {
                engine.tick()
            }
            engine.start()
        }
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let upperContainer = createUpperContainer()
        let lowerContainer = createLowerContainer()

        stackView.addArrangedSubview(upperContainer)
        stackView.addArrangedSubview(lowerContainer)
    }

    private func createUpperContainer() -> UIView {
        let container = UIView()
        container.backgroundColor = .systemBlue.withAlphaComponent(0.1)

        phaseLabel.font = .systemFont(ofSize: 24, weight: .semibold)
        phaseLabel.textAlignment = .center
        phaseLabel.adjustsFontSizeToFitWidth = true
        phaseLabel.translatesAutoresizingMaskIntoConstraints = false

        timeLabel.font = .monospacedDigitSystemFont(ofSize: 72, weight: .bold)
        timeLabel.textAlignment = .center
        timeLabel.adjustsFontSizeToFitWidth = true
        timeLabel.translatesAutoresizingMaskIntoConstraints = false

        roundLabel.font = .systemFont(ofSize: 18)
        roundLabel.textAlignment = .center
        roundLabel.adjustsFontSizeToFitWidth = true
        roundLabel.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(phaseLabel)
        container.addSubview(timeLabel)
        container.addSubview(roundLabel)

        NSLayoutConstraint.activate([
            phaseLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            phaseLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor, constant: -60),

            timeLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            timeLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            roundLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            roundLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor, constant: 60)
        ])

        return container
    }

    private func createLowerContainer() -> UIView {
        let container = UIView()
        container.backgroundColor = .systemRed.withAlphaComponent(0.1)

        heartRateLabel.text = "--"
        heartRateLabel.font = .monospacedDigitSystemFont(ofSize: 72, weight: .bold)
        heartRateLabel.textAlignment = .center
        heartRateLabel.adjustsFontSizeToFitWidth = true
        heartRateLabel.translatesAutoresizingMaskIntoConstraints = false

        bpmLabel.text = "BPM"
        bpmLabel.font = .systemFont(ofSize: 24, weight: .medium)
        bpmLabel.textAlignment = .center
        bpmLabel.translatesAutoresizingMaskIntoConstraints = false

        connectionLabel.text = "Not connected"
        connectionLabel.font = .systemFont(ofSize: 16)
        connectionLabel.textAlignment = .center
        connectionLabel.textColor = .systemGray
        connectionLabel.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(heartRateLabel)
        container.addSubview(bpmLabel)
        container.addSubview(connectionLabel)

        NSLayoutConstraint.activate([
            heartRateLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            heartRateLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor, constant: -40),

            bpmLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            bpmLabel.topAnchor.constraint(equalTo: heartRateLabel.bottomAnchor, constant: 8),

            connectionLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            connectionLabel.topAnchor.constraint(equalTo: bpmLabel.bottomAnchor, constant: 16)
        ])

        return container
    }

    private func updateUI() {
        phaseLabel.text = engine.phase.rawValue
        timeLabel.text = formatTime(engine.remainingSeconds)
        roundLabel.text = formatRound()
    }

    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }

    private func formatRound() -> String {
        switch engine.phase {
        case .warmUp:
            return "Warm Up"
        case .work, .rest:
            return "Round \(engine.currentRound) / \(8)"
        case .coolDown:
            return "Cool Down"
        case .finished:
            return "Finished"
        }
    }

    func engineDidUpdateState(_ engine: IntervalEngine) {
        updateUI()
    }

    func engineDidTransitionToPhase(_ engine: IntervalEngine, phase: IntervalPhase) {
        updateUI()
    }

    func engineDidFinish(_ engine: IntervalEngine) {
        updateUI()
    }

    func heartRateMonitor(_ monitor: HeartRateMonitor, didUpdateHeartRate bpm: Int) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.heartRateLabel.text = "\(bpm)"

            UIView.animate(withDuration: 0.1) {
                self.heartRateLabel.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            } completion: { _ in
                UIView.animate(withDuration: 0.1) {
                    self.heartRateLabel.transform = .identity
                }
            }
        }
    }

    func heartRateMonitor(_ monitor: HeartRateMonitor, didChangeState state: HeartRateMonitorState) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            switch state {
            case .idle:
                self.connectionLabel.text = "Not connected"
            case .scanning:
                self.connectionLabel.text = "Scanning…"
            case .connecting:
                self.connectionLabel.text = "Connecting…"
            case .connected:
                self.connectionLabel.text = "Connected"
            case .disconnected:
                self.connectionLabel.text = "Disconnected"
                self.heartRateLabel.text = "--"
            }
        }
    }

    func heartRateMonitor(_ monitor: HeartRateMonitor, didFailWithError error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.connectionLabel.text = "Error"
        }
    }
}
