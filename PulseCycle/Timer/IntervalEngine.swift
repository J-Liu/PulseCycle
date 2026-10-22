// SPDX-FileCopyrightText: 2026 Jia Liu
// SPDX-License-Identifier: Apache-2.0

import Foundation

protocol IntervalEngineDelegate: AnyObject {
    func engineDidUpdateState(_ engine: IntervalEngine)
    func engineDidTransitionToPhase(_ engine: IntervalEngine, phase: IntervalPhase)
    func engineDidFinish(_ engine: IntervalEngine)
}

class IntervalEngine {
    private let config: WorkoutConfig
    weak var delegate: IntervalEngineDelegate?

    private(set) var phase: IntervalPhase = .warmUp
    private(set) var remainingSeconds: Int
    private(set) var currentRound: Int = 0
    private(set) var totalElapsedSeconds: Int = 0
    let totalDuration: Int

    private var timer: Timer?
    private var isRunning = false

    init(config: WorkoutConfig) {
        self.config = config
        self.remainingSeconds = config.warmUpSeconds
        self.totalDuration = config.warmUpSeconds +
            (config.workSeconds + config.restSeconds) * config.rounds -
            config.restSeconds + config.coolDownSeconds
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        scheduleTimer()
    }

    func pause() {
        guard isRunning else { return }
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    func resume() {
        start()
    }

    func reset() {
        pause()
        phase = .warmUp
        remainingSeconds = config.warmUpSeconds
        currentRound = 0
        totalElapsedSeconds = 0
        delegate?.engineDidUpdateState(self)
    }

    private func scheduleTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func tick() {
        guard phase != .finished else { return }

        if remainingSeconds > 1 {
            remainingSeconds -= 1
            totalElapsedSeconds += 1
            delegate?.engineDidUpdateState(self)
        } else {
            remainingSeconds = 0
            totalElapsedSeconds += 1
            delegate?.engineDidUpdateState(self)
            advancePhase()
        }
    }

    private func advancePhase() {
        switch phase {
        case .warmUp:
            phase = .work
            currentRound = 1
            remainingSeconds = config.workSeconds
        case .work:
            if currentRound >= config.rounds {
                phase = .coolDown
                remainingSeconds = config.coolDownSeconds
            } else {
                phase = .rest
                remainingSeconds = config.restSeconds
            }
        case .rest:
            phase = .work
            currentRound += 1
            remainingSeconds = config.workSeconds
        case .coolDown:
            phase = .finished
            remainingSeconds = 0
            pause()
            delegate?.engineDidFinish(self)
        case .finished:
            break
        }

        delegate?.engineDidTransitionToPhase(self, phase: phase)
        delegate?.engineDidUpdateState(self)
    }
}
