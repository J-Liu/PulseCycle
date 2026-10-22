// SPDX-FileCopyrightText: 2026 Jia Liu
// SPDX-License-Identifier: Apache-2.0

import UIKit

class MainViewController: UIViewController {
    private let phaseLabel = UILabel()
    private let timeLabel = UILabel()
    private let roundLabel = UILabel()
    private let heartRateLabel = UILabel()
    private let bpmLabel = UILabel()
    private let connectionLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
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

        phaseLabel.text = "WORK"
        phaseLabel.font = .systemFont(ofSize: 24, weight: .semibold)
        phaseLabel.textAlignment = .center
        phaseLabel.adjustsFontSizeToFitWidth = true
        phaseLabel.translatesAutoresizingMaskIntoConstraints = false

        timeLabel.text = "00:30"
        timeLabel.font = .monospacedDigitSystemFont(ofSize: 72, weight: .bold)
        timeLabel.textAlignment = .center
        timeLabel.adjustsFontSizeToFitWidth = true
        timeLabel.translatesAutoresizingMaskIntoConstraints = false

        roundLabel.text = "Round 2 / 8"
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

        heartRateLabel.text = "142"
        heartRateLabel.font = .monospacedDigitSystemFont(ofSize: 72, weight: .bold)
        heartRateLabel.textAlignment = .center
        heartRateLabel.adjustsFontSizeToFitWidth = true
        heartRateLabel.translatesAutoresizingMaskIntoConstraints = false

        bpmLabel.text = "BPM"
        bpmLabel.font = .systemFont(ofSize: 24, weight: .medium)
        bpmLabel.textAlignment = .center
        bpmLabel.translatesAutoresizingMaskIntoConstraints = false

        connectionLabel.text = "Connected"
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
}
