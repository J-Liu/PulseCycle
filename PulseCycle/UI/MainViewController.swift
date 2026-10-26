// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright 2026 Jia Liu
// Licensed under AGPL-3.0-or-later with an additional permission
// under Section 7. See LICENSE for details.

import UIKit

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

    private let opView = UIView()
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
    private var isPreparing = false
    private var prepareCountdown: Int = 0

    init() {
        heartRateMonitor = HeartRateMonitor()
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        heartRateMonitor.delegate = self
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
        if isPreparing {
            return
        }

        if isRunning {
            engine.pause()
            isRunning = false
        } else {
            let profile = ProfileManager.shared.currentProfile
            if hasReset && profile.prepareCountingSoundEnabled && engine.phase == .warmUp && engine.remainingSeconds == (profile.warmUpEnabled ? profile.warmUpSeconds : 0) {
                startCountdown()
            } else {
                engine.start()
                isRunning = true
            }
            hasReset = false
        }
        updateGoButton()
    }

    private func startCountdown() {
        let profile = ProfileManager.shared.currentProfile
        isPreparing = true
        prepareCountdown = profile.prepareTime
        updateUI()

        let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }

            SoundManager.shared.playCountdownBeep()
            self.prepareCountdown -= 1
            self.updateUI()

            if self.prepareCountdown == 0 {
                timer.invalidate()
                self.isPreparing = false
                self.engine.start()
                self.isRunning = true
                self.updateUI()
                self.updateGoButton()
            }
        }
        timer.fire()
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
            goButton.setTitle(L("Pause"), for: .normal)
        } else if engine.phase == .finished {
            goButton.setTitle(L("Go"), for: .normal)
        } else if hasReset {
            goButton.setTitle(L("Go"), for: .normal)
        } else {
            goButton.setTitle(L("Resume"), for: .normal)
        }
        settingsButton.isEnabled = !isRunning && (hasReset || engine.phase == .finished)
        settingsButton.alpha = settingsButton.isEnabled ? 1.0 : 0.5
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        setupTimerArea()
        setupHeader()
        setupOpView()
        setupHeartRateArea()
    }

    private func setupHeader() {
        headerView.backgroundColor = .clear
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)

        workLabel.text = L("Work")
        workLabel.font = .systemFont(ofSize: 20, weight: .bold)
        workLabel.textAlignment = .left
        workLabel.translatesAutoresizingMaskIntoConstraints = false

        workTimeLabel.font = .monospacedDigitSystemFont(ofSize: 20, weight: .bold)
        workTimeLabel.textAlignment = .left
        workTimeLabel.translatesAutoresizingMaskIntoConstraints = false

        profileLabel.font = .systemFont(ofSize: 22, weight: .bold)
        profileLabel.textAlignment = .center
        profileLabel.translatesAutoresizingMaskIntoConstraints = false

        restLabel.text = L("Rest")
        restLabel.font = .systemFont(ofSize: 20, weight: .bold)
        restLabel.textAlignment = .right
        restLabel.translatesAutoresizingMaskIntoConstraints = false

        restTimeLabel.font = .monospacedDigitSystemFont(ofSize: 20, weight: .bold)
        restTimeLabel.textAlignment = .right
        restTimeLabel.translatesAutoresizingMaskIntoConstraints = false

        headerView.addSubview(workLabel)
        headerView.addSubview(workTimeLabel)
        headerView.addSubview(profileLabel)
        headerView.addSubview(restLabel)
        headerView.addSubview(restTimeLabel)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: timerContainer!.topAnchor, constant: 60),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
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
            restTimeLabel.topAnchor.constraint(equalTo: restLabel.bottomAnchor, constant: 4)
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

        timeLabel.font = .monospacedDigitSystemFont(ofSize: 140, weight: .bold)
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
            timerContainer.topAnchor.constraint(equalTo: view.topAnchor),
            timerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            timerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            timerContainer.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.65),

            phaseLabel.centerXAnchor.constraint(equalTo: timerContainer.centerXAnchor),
            phaseLabel.centerYAnchor.constraint(equalTo: timerCenterY, constant: -80),
            phaseLabel.leadingAnchor.constraint(equalTo: timerContainer.leadingAnchor, constant: 16),
            phaseLabel.trailingAnchor.constraint(equalTo: timerContainer.trailingAnchor, constant: -16),

            timeLabel.centerXAnchor.constraint(equalTo: timerContainer.centerXAnchor),
            timeLabel.centerYAnchor.constraint(equalTo: timerCenterY),
            timeLabel.leadingAnchor.constraint(equalTo: timerContainer.leadingAnchor, constant: 16),
            timeLabel.trailingAnchor.constraint(equalTo: timerContainer.trailingAnchor, constant: -16),

            roundLabel.centerXAnchor.constraint(equalTo: timerContainer.centerXAnchor),
            roundLabel.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 20)
        ])

        self.timerContainer = timerContainer
    }

    private var timerContainer: UIView?

    private func setupHeartRateArea() {
        heartRateContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(heartRateContainer)

        heartRateLabel.text = "--"
        heartRateLabel.font = .monospacedDigitSystemFont(ofSize: 140, weight: .bold)
        heartRateLabel.textAlignment = .center
        heartRateLabel.adjustsFontSizeToFitWidth = true
        heartRateLabel.translatesAutoresizingMaskIntoConstraints = false

        bpmLabel.text = L("BPM")
        bpmLabel.font = .systemFont(ofSize: 24, weight: .medium)
        bpmLabel.textAlignment = .center
        bpmLabel.translatesAutoresizingMaskIntoConstraints = false

        connectionLabel.text = L("Not connected")
        connectionLabel.font = .systemFont(ofSize: 16)
        connectionLabel.textAlignment = .center
        connectionLabel.textColor = .systemGray
        connectionLabel.translatesAutoresizingMaskIntoConstraints = false

        heartRateContainer.addSubview(heartRateLabel)
        heartRateContainer.addSubview(bpmLabel)
        heartRateContainer.addSubview(connectionLabel)

        NSLayoutConstraint.activate([
            heartRateContainer.topAnchor.constraint(equalTo: timerContainer!.bottomAnchor),
            heartRateContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            heartRateContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            heartRateContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            heartRateLabel.centerXAnchor.constraint(equalTo: heartRateContainer.centerXAnchor),
            heartRateLabel.centerYAnchor.constraint(equalTo: heartRateContainer.centerYAnchor, constant: -40),

            bpmLabel.centerXAnchor.constraint(equalTo: heartRateContainer.centerXAnchor),
            bpmLabel.topAnchor.constraint(equalTo: heartRateLabel.bottomAnchor, constant: 8),

            connectionLabel.centerXAnchor.constraint(equalTo: heartRateContainer.centerXAnchor),
            connectionLabel.topAnchor.constraint(equalTo: bpmLabel.bottomAnchor, constant: 16)
        ])
    }

    private func setupOpView() {
        opView.backgroundColor = .clear
        opView.translatesAutoresizingMaskIntoConstraints = false
        timerContainer!.addSubview(opView)

        // Go button - larger, bold, red background
        goButton.setTitle(L("Go"), for: .normal)
        goButton.titleLabel?.font = .systemFont(ofSize: 28, weight: .bold)
        goButton.setTitleColor(.white, for: .normal)
        goButton.backgroundColor = .systemRed
        goButton.layer.cornerRadius = 12
        goButton.layer.borderWidth = 2
        goButton.layer.borderColor = UIColor.white.cgColor
        goButton.translatesAutoresizingMaskIntoConstraints = false

        // Settings button - red background, white text, white border
        settingsButton.setTitle(L("Settings"), for: .normal)
        settingsButton.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        settingsButton.setTitleColor(.white, for: .normal)
        settingsButton.backgroundColor = .systemRed
        settingsButton.layer.cornerRadius = 10
        settingsButton.layer.borderWidth = 2
        settingsButton.layer.borderColor = UIColor.white.cgColor
        settingsButton.translatesAutoresizingMaskIntoConstraints = false

        // Reset button - red background, white text, white border
        resetButton.setTitle(L("Reset"), for: .normal)
        resetButton.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        resetButton.setTitleColor(.white, for: .normal)
        resetButton.backgroundColor = .systemRed
        resetButton.layer.cornerRadius = 10
        resetButton.layer.borderWidth = 2
        resetButton.layer.borderColor = UIColor.white.cgColor
        resetButton.translatesAutoresizingMaskIntoConstraints = false

        opView.addSubview(goButton)
        opView.addSubview(settingsButton)
        opView.addSubview(resetButton)

        NSLayoutConstraint.activate([
            opView.leadingAnchor.constraint(equalTo: timerContainer!.leadingAnchor),
            opView.trailingAnchor.constraint(equalTo: timerContainer!.trailingAnchor),
            opView.bottomAnchor.constraint(equalTo: timerContainer!.bottomAnchor),
            opView.heightAnchor.constraint(equalToConstant: 120),

            goButton.centerXAnchor.constraint(equalTo: opView.centerXAnchor),
            goButton.topAnchor.constraint(equalTo: opView.topAnchor, constant: 12),
            goButton.widthAnchor.constraint(equalToConstant: 140),
            goButton.heightAnchor.constraint(equalToConstant: 56),

            settingsButton.leadingAnchor.constraint(equalTo: opView.leadingAnchor, constant: 24),
            settingsButton.centerYAnchor.constraint(equalTo: goButton.centerYAnchor),
            settingsButton.widthAnchor.constraint(equalToConstant: 100),
            settingsButton.heightAnchor.constraint(equalToConstant: 48),

            resetButton.trailingAnchor.constraint(equalTo: opView.trailingAnchor, constant: -24),
            resetButton.centerYAnchor.constraint(equalTo: goButton.centerYAnchor),
            resetButton.widthAnchor.constraint(equalToConstant: 100),
            resetButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }

    private func updateUI() {
        let profile = ProfileManager.shared.currentProfile
        profileLabel.text = "\(profile.name) ▼"
        workTimeLabel.text = formatTime(profile.workSeconds)
        restTimeLabel.text = formatTime(profile.restSeconds)

        if isPreparing {
            phaseLabel.text = L("Prepare")
            timeLabel.text = "\(prepareCountdown)"
            roundLabel.text = ""
        } else {
            phaseLabel.text = formatPhase(engine.phase)
            timeLabel.text = formatTime(engine.remainingSeconds)
            roundLabel.text = formatRound()
        }

        updateColors()
        updateGoButton()
    }

    private func updateColors() {
        let profile = ProfileManager.shared.currentProfile
        let workColor = UIColor(hex: profile.workColor) ?? .systemRed.withAlphaComponent(0.15)
        let restColor = UIColor(hex: profile.restColor) ?? .systemGray.withAlphaComponent(0.15)
        let hrColor = UIColor(hex: profile.heartRateColor) ?? .systemRed.withAlphaComponent(0.1)
        let prepareColor = UIColor(hex: profile.prepareColor) ?? .systemRed.withAlphaComponent(0.05)
        let warmUpColor = UIColor(hex: profile.warmUpColor) ?? .systemRed.withAlphaComponent(0.1)
        let coolDownColor = UIColor(hex: profile.coolDownColor) ?? .systemGray.withAlphaComponent(0.2)

        let timerColor: UIColor
        if isPreparing {
            timerColor = prepareColor
        } else {
            switch engine.phase {
            case .warmUp:
                timerColor = warmUpColor
            case .work:
                timerColor = workColor
            case .rest:
                timerColor = restColor
            case .coolDown:
                timerColor = coolDownColor
            case .finished:
                timerColor = restColor
            }
        }

        headerView.backgroundColor = timerColor
        timerContainer?.backgroundColor = timerColor
        heartRateContainer.backgroundColor = hrColor
    }

    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }

    private func formatPhase(_ phase: IntervalPhase) -> String {
        switch phase {
        case .warmUp:
            return L("Warm Up")
        case .work:
            return L("Work")
        case .rest:
            return L("Rest")
        case .coolDown:
            return L("Cool Down")
        case .finished:
            return L("Finished")
        }
    }

    private func formatRound() -> String {
        let profile = ProfileManager.shared.currentProfile
        switch engine.phase {
        case .warmUp:
            return L("Warm Up")
        case .work, .rest:
            return String(format: L("Round %d / %d"), engine.currentRound, profile.rounds)
        case .coolDown:
            return L("Cool Down")
        case .finished:
            return L("Finished")
        }
    }

    func engineDidUpdateState(_ engine: IntervalEngine) {
        DispatchQueue.main.async { [weak self] in
            self?.updateUI()

            let profile = ProfileManager.shared.currentProfile

            // Play ending notify sound 10 seconds before phase ends (if phase >= 15s)
            if profile.endingNotifySoundEnabled && engine.remainingSeconds == 10 {
                let phaseDuration: Int
                switch engine.phase {
                case .work:
                    phaseDuration = profile.workSeconds
                case .warmUp:
                    phaseDuration = profile.warmUpEnabled ? profile.warmUpSeconds : 0
                case .coolDown:
                    phaseDuration = profile.coolDownEnabled ? profile.coolDownSeconds : 0
                default:
                    phaseDuration = 0
                }

                if phaseDuration >= 15 {
                    SoundManager.shared.playPreRoundWarningSound()
                }
            }

            // Play phase end sound when phase ends (except coolDown, which is handled by engineDidFinish)
            if profile.endSoundEnabled && engine.remainingSeconds == 0 && engine.phase != .finished && engine.phase != .coolDown {
                SoundManager.shared.playRoundEndSound()
            }
        }
    }

    func engineDidTransitionToPhase(_ engine: IntervalEngine, phase: IntervalPhase) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.updateUI()
            self.impactGenerator.impactOccurred()
            UIApplication.shared.isIdleTimerDisabled = true

            // Play phase start sound for warmUp, work, coolDown
            let profile = ProfileManager.shared.currentProfile
            if profile.startSoundEnabled && (phase == .warmUp || phase == .work || phase == .coolDown) {
                SoundManager.shared.playPhaseStartSound()
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

            // Play round end sound
            let profile = ProfileManager.shared.currentProfile
            if profile.endSoundEnabled {
                SoundManager.shared.playRoundEndSound()
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
                self.connectionLabel.text = L("Not connected")
            case .scanning:
                self.connectionLabel.text = L("Scanning…")
            case .connecting:
                self.connectionLabel.text = L("Connecting…")
            case .connected:
                self.connectionLabel.text = L("Connected")
            case .disconnected:
                self.connectionLabel.text = L("Disconnected")
                self.heartRateLabel.text = "--"
            }
        }
    }

    func heartRateMonitor(_ monitor: HeartRateMonitor, didFailWithError error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.connectionLabel.text = L("Error")
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

    func toHexString() -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)

        let rgb: Int = (Int)(r * 255) << 16 | (Int)(g * 255) << 8 | (Int)(b * 255) << 0
        return String(format: "#%06x", rgb)
    }
}
