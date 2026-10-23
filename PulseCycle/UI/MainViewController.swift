// SPDX-FileCopyrightText: 2026 Jia Liu
// SPDX-License-Identifier: Apache-2.0

import UIKit
import AudioToolbox

class MainViewController: UIViewController, IntervalEngineDelegate, HeartRateMonitorDelegate {
    private let headerView = UIView()
    private let workLabel = UILabel()
    private let workTimeLabel = UILabel()
    private let profileLabel = UILabel()
    private let restLabel = UILabel()
    private let restTimeLabel = UILabel()

    private let phaseLabel = UILabel()
    private let timeLabel = UILabel()
    private let roundLabel = UILabel()

    private let heartRateContainer = UIView()
    private let heartRateLabel = UILabel()
    private let bpmLabel = UILabel()
    private let connectionLabel = UILabel()

    private let bottomView = UIView()
    private let goButton = UIButton(type: .system)
    private let settingsButton = UIButton(type: .system)
    private let resetButton = UIButton(type: .system)

    private var engine: IntervalEngine!
    private let heartRateMonitor: HeartRateMonitor
    private var backgroundTimestamp: Date?
    private let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let notificationGenerator = UINotificationFeedbackGenerator()

    private var isRunning = false
    private var hasReset = true

    init() {
        heartRateMonitor = HeartRateMonitor()
        super.init(nibName: nil, bundle: nil)
        heartRateMonitor.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupEngine()
        setupUI()
        setupActions()
        updateUI()
        heartRateMonitor.startScanning()
        impactGenerator.prepare()
        notificationGenerator.prepare()

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

    private func setupEngine() {
        let profile = ProfileManager.shared.currentProfile
        let config = WorkoutConfig(
            warmUpSeconds: profile.warmUpEnabled ? profile.warmUpSeconds : 0,
            workSeconds: profile.workSeconds,
            restSeconds: profile.restSeconds,
            rounds: profile.rounds,
            coolDownSeconds: profile.coolDownEnabled ? profile.coolDownSeconds : 0
        )
        engine = IntervalEngine(config: config)
        engine.delegate = self
    }

    private func setupActions() {
        let profileTap = UITapGestureRecognizer(target: self, action: #selector(showProfileList))
        profileLabel.isUserInteractionEnabled = true
        profileLabel.addGestureRecognizer(profileTap)

        goButton.addTarget(self, action: #selector(handleGo), for: .touchUpInside)
        settingsButton.addTarget(self, action: #selector(handleSettings), for: .touchUpInside)
        resetButton.addTarget(self, action: #selector(handleReset), for: .touchUpInside)
    }

    @objc private func showProfileList() {
        let vc = ProfileListViewController()
        vc.onSelect = { [weak self] in
            self?.setupEngine()
            self?.updateUI()
        }
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .pageSheet
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
        }
        present(nav, animated: true)
    }

    @objc private func handleGo() {
        if isRunning {
            engine.pause()
        } else {
            engine.start()
        }
        isRunning.toggle()
        updateGoButton()
    }

    @objc private func handleSettings() {
        let vc = SettingsViewController()
        vc.onSave = { [weak self] in
            self?.setupEngine()
            self?.updateUI()
        }
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .pageSheet
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.large()]
        }
        present(nav, animated: true)
    }

    @objc private func handleReset() {
        engine.reset()
        isRunning = false
        hasReset = true
        updateGoButton()
        updateUI()
    }

    @objc private func handleResignActive() {
        backgroundTimestamp = Date()
        if isRunning {
            engine.pause()
        }
    }

    @objc private func handleEnterForeground() {
        guard let timestamp = backgroundTimestamp else { return }
        let elapsed = Int(Date().timeIntervalSince(timestamp))
        backgroundTimestamp = nil

        if elapsed > 0 && engine.phase != .finished && engine.phase != .warmUp {
            for _ in 0..<min(elapsed, engine.remainingSeconds) {
                engine.tick()
            }
        }
        if isRunning {
            engine.start()
        }
    }

    private func updateGoButton() {
        if isRunning {
            goButton.setTitle("Pause", for: .normal)
        } else if engine.phase == .finished {
            goButton.setTitle("Go", for: .normal)
        } else {
            goButton.setTitle("Go", for: .normal)
        }
        settingsButton.isEnabled = hasReset
        settingsButton.alpha = hasReset ? 1.0 : 0.5
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        setupHeader()
        setupTimerArea()
        setupHeartRateArea()
        setupBottomButtons()
    }

    private func setupHeader() {
        headerView.backgroundColor = .systemBackground
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)

        workLabel.text = "Work"
        workLabel.font = .systemFont(ofSize: 14, weight: .medium)
        workLabel.textAlignment = .left
        workLabel.translatesAutoresizingMaskIntoConstraints = false

        workTimeLabel.font = .monospacedDigitSystemFont(ofSize: 14, weight: .bold)
        workTimeLabel.textAlignment = .left
        workTimeLabel.translatesAutoresizingMaskIntoConstraints = false

        profileLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        profileLabel.textAlignment = .center
        profileLabel.textColor = .systemBlue
        profileLabel.translatesAutoresizingMaskIntoConstraints = false

        restLabel.text = "Rest"
        restLabel.font = .systemFont(ofSize: 14, weight: .medium)
        restLabel.textAlignment = .right
        restLabel.translatesAutoresizingMaskIntoConstraints = false

        restTimeLabel.font = .monospacedDigitSystemFont(ofSize: 14, weight: .bold)
        restTimeLabel.textAlignment = .right
        restTimeLabel.translatesAutoresizingMaskIntoConstraints = false

        headerView.addSubview(workLabel)
        headerView.addSubview(workTimeLabel)
        headerView.addSubview(profileLabel)
        headerView.addSubview(restLabel)
        headerView.addSubview(restTimeLabel)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            headerView.heightAnchor.constraint(equalToConstant: 50),

            workLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            workLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 8),

            workTimeLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            workTimeLabel.topAnchor.constraint(equalTo: workLabel.bottomAnchor, constant: 2),

            profileLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            profileLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            restLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            restLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 8),

            restTimeLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            restTimeLabel.topAnchor.constraint(equalTo: restLabel.bottomAnchor, constant: 2)
        ])
    }

    private func setupTimerArea() {
        let timerContainer = UIView()
        timerContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(timerContainer)

        let timerCenterY = timerContainer.centerYAnchor

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

        timerContainer.addSubview(phaseLabel)
        timerContainer.addSubview(timeLabel)
        timerContainer.addSubview(roundLabel)

        NSLayoutConstraint.activate([
            timerContainer.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            timerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            timerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            timerContainer.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.45),

            phaseLabel.centerXAnchor.constraint(equalTo: timerContainer.centerXAnchor),
            phaseLabel.centerYAnchor.constraint(equalTo: timerCenterY, constant: -60),
            phaseLabel.leadingAnchor.constraint(equalTo: timerContainer.leadingAnchor, constant: 16),
            phaseLabel.trailingAnchor.constraint(equalTo: timerContainer.trailingAnchor, constant: -16),

            timeLabel.centerXAnchor.constraint(equalTo: timerContainer.centerXAnchor),
            timeLabel.centerYAnchor.constraint(equalTo: timerCenterY),
            timeLabel.leadingAnchor.constraint(equalTo: timerContainer.leadingAnchor, constant: 16),
            timeLabel.trailingAnchor.constraint(equalTo: timerContainer.trailingAnchor, constant: -16),

            roundLabel.centerXAnchor.constraint(equalTo: timerContainer.centerXAnchor),
            roundLabel.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 16)
        ])

        self.timerContainer = timerContainer
    }

    private var timerContainer: UIView?

    private func setupHeartRateArea() {
        heartRateContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(heartRateContainer)

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

        heartRateContainer.addSubview(heartRateLabel)
        heartRateContainer.addSubview(bpmLabel)
        heartRateContainer.addSubview(connectionLabel)

        NSLayoutConstraint.activate([
            heartRateContainer.topAnchor.constraint(equalTo: view.centerYAnchor),
            heartRateContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            heartRateContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            heartRateContainer.bottomAnchor.constraint(equalTo: bottomView.topAnchor),

            heartRateLabel.centerXAnchor.constraint(equalTo: heartRateContainer.centerXAnchor),
            heartRateLabel.centerYAnchor.constraint(equalTo: heartRateContainer.centerYAnchor, constant: -40),

            bpmLabel.centerXAnchor.constraint(equalTo: heartRateContainer.centerXAnchor),
            bpmLabel.topAnchor.constraint(equalTo: heartRateLabel.bottomAnchor, constant: 8),

            connectionLabel.centerXAnchor.constraint(equalTo: heartRateContainer.centerXAnchor),
            connectionLabel.topAnchor.constraint(equalTo: bpmLabel.bottomAnchor, constant: 16)
        ])
    }

    private func setupBottomButtons() {
        bottomView.backgroundColor = .systemBackground
        bottomView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomView)

        goButton.setTitle("Go", for: .normal)
        goButton.titleLabel?.font = .systemFont(ofSize: 24, weight: .bold)
        goButton.translatesAutoresizingMaskIntoConstraints = false

        settingsButton.setTitle("Settings", for: .normal)
        settingsButton.titleLabel?.font = .systemFont(ofSize: 16)
        settingsButton.translatesAutoresizingMaskIntoConstraints = false

        resetButton.setTitle("Reset", for: .normal)
        resetButton.titleLabel?.font = .systemFont(ofSize: 16)
        resetButton.translatesAutoresizingMaskIntoConstraints = false

        bottomView.addSubview(goButton)
        bottomView.addSubview(settingsButton)
        bottomView.addSubview(resetButton)

        NSLayoutConstraint.activate([
            bottomView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            bottomView.heightAnchor.constraint(equalToConstant: 100),

            goButton.centerXAnchor.constraint(equalTo: bottomView.centerXAnchor),
            goButton.topAnchor.constraint(equalTo: bottomView.topAnchor, constant: 8),

            settingsButton.leadingAnchor.constraint(equalTo: bottomView.leadingAnchor, constant: 24),
            settingsButton.centerYAnchor.constraint(equalTo: goButton.centerYAnchor),

            resetButton.trailingAnchor.constraint(equalTo: bottomView.trailingAnchor, constant: -24),
            resetButton.centerYAnchor.constraint(equalTo: goButton.centerYAnchor)
        ])
    }

    private func updateUI() {
        let profile = ProfileManager.shared.currentProfile
        profileLabel.text = profile.name
        workTimeLabel.text = formatTime(profile.workSeconds)
        restTimeLabel.text = formatTime(profile.restSeconds)

        phaseLabel.text = engine.phase.rawValue
        timeLabel.text = formatTime(engine.remainingSeconds)
        roundLabel.text = formatRound()

        updateColors()
        updateGoButton()
    }

    private func updateColors() {
        let profile = ProfileManager.shared.currentProfile
        let workColor = UIColor(hex: profile.workColor) ?? .systemRed.withAlphaComponent(0.15)
        let restColor = UIColor(hex: profile.restColor) ?? .systemGray.withAlphaComponent(0.15)
        let hrColor = UIColor(hex: profile.heartRateColor) ?? .systemRed.withAlphaComponent(0.1)

        timerContainer?.backgroundColor = (engine.phase == .work) ? workColor : restColor
        heartRateContainer.backgroundColor = hrColor
    }

    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }

    private func formatRound() -> String {
        let profile = ProfileManager.shared.currentProfile
        switch engine.phase {
        case .warmUp:
            return "Warm Up"
        case .work, .rest:
            return "Round \(engine.currentRound) / \(profile.rounds)"
        case .coolDown:
            return "Cool Down"
        case .finished:
            return "Finished"
        }
    }

    func engineDidUpdateState(_ engine: IntervalEngine) {
        DispatchQueue.main.async { [weak self] in
            self?.updateUI()
        }
    }

    func engineDidTransitionToPhase(_ engine: IntervalEngine, phase: IntervalPhase) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.updateUI()
            self.impactGenerator.impactOccurred()
            UIApplication.shared.isIdleTimerDisabled = true

            let profile = ProfileManager.shared.currentProfile
            if profile.warningSoundEnabled && phase == .rest && engine.currentRound > 0 {
                AudioServicesPlaySystemSound(1052)
            }
        }
    }

    func engineDidFinish(_ engine: IntervalEngine) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.updateUI()
            self.notificationGenerator.notificationOccurred(.success)
            UIApplication.shared.isIdleTimerDisabled = false
            self.isRunning = false
            self.hasReset = false
            self.updateGoButton()

            let profile = ProfileManager.shared.currentProfile
            if profile.endSoundEnabled {
                AudioServicesPlaySystemSound(1057)
            }
        }
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

extension UIColor {
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
}
