// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright 2026 Jia Liu
// Licensed under AGPL-3.0-or-later with an additional permission
// under Section 7. See LICENSE for details.

import UIKit

class TimePickerViewController: UIViewController {
    private let pickerView = UIPickerView()
    private let titleText: String
    private let maxValue: Int
    private let step: Int
    private let completion: (Int) -> Void

    private var minutes: [Int] = []
    private var seconds: [Int] = []
    private var initialMinutes: Int = 0
    private var initialSeconds: Int = 0

    init(title: String, currentValue: Int, maxValue: Int, step: Int, completion: @escaping (Int) -> Void) {
        self.titleText = title
        self.maxValue = maxValue
        self.step = step
        self.completion = completion
        super.init(nibName: nil, bundle: nil)

        // Calculate minutes and seconds arrays
        let maxMinutes = maxValue / 60
        minutes = Array(0...maxMinutes)

        // Generate seconds based on step
        var secs = 0
        while secs < 60 {
            seconds.append(secs)
            secs += step
        }

        // Calculate initial values
        initialMinutes = currentValue / 60
        initialSeconds = (currentValue % 60 / step) * step
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)

        // Container
        let containerView = UIView()
        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 16
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)

        // Title
        let titleLabel = UILabel()
        titleLabel.text = titleText
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)

        // Labels for units
        let minuteLabel = UILabel()
        minuteLabel.text = L("min")
        minuteLabel.font = .systemFont(ofSize: 16)
        minuteLabel.textAlignment = .center
        minuteLabel.translatesAutoresizingMaskIntoConstraints = false

        let secondLabel = UILabel()
        secondLabel.text = L("sec")
        secondLabel.font = .systemFont(ofSize: 16)
        secondLabel.textAlignment = .center
        secondLabel.translatesAutoresizingMaskIntoConstraints = false

        // Picker
        pickerView.delegate = self
        pickerView.dataSource = self
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(pickerView)
        containerView.addSubview(minuteLabel)
        containerView.addSubview(secondLabel)

        // Buttons
        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle(L("Cancel"), for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false

        let doneButton = UIButton(type: .system)
        doneButton.setTitle(L("Done"), for: .normal)
        doneButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        doneButton.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
        doneButton.translatesAutoresizingMaskIntoConstraints = false

        let buttonStack = UIStackView(arrangedSubviews: [cancelButton, doneButton])
        buttonStack.axis = .horizontal
        buttonStack.distribution = .fillEqually
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(buttonStack)

        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 300),
            containerView.heightAnchor.constraint(equalToConstant: 300),

            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),

            pickerView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            pickerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 40),
            pickerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -40),
            pickerView.heightAnchor.constraint(equalToConstant: 180),

            minuteLabel.leadingAnchor.constraint(equalTo: pickerView.leadingAnchor),
            minuteLabel.trailingAnchor.constraint(equalTo: pickerView.centerXAnchor, constant: -10),
            minuteLabel.topAnchor.constraint(equalTo: pickerView.topAnchor, constant: 70),

            secondLabel.leadingAnchor.constraint(equalTo: pickerView.centerXAnchor, constant: 10),
            secondLabel.trailingAnchor.constraint(equalTo: pickerView.trailingAnchor),
            secondLabel.topAnchor.constraint(equalTo: pickerView.topAnchor, constant: 70),

            buttonStack.topAnchor.constraint(equalTo: pickerView.bottomAnchor, constant: 8),
            buttonStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            buttonStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            buttonStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
            buttonStack.heightAnchor.constraint(equalToConstant: 44)
        ])

        // Set initial values
        pickerView.selectRow(initialMinutes, inComponent: 0, animated: false)
        pickerView.selectRow(initialSeconds / step, inComponent: 1, animated: false)
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func doneTapped() {
        let selectedMinutes = pickerView.selectedRow(inComponent: 0)
        let selectedSecondsIndex = pickerView.selectedRow(inComponent: 1)
        let selectedSeconds = seconds[selectedSecondsIndex]

        let totalSeconds = selectedMinutes * 60 + selectedSeconds
        completion(totalSeconds)
        dismiss(animated: true)
    }
}

extension TimePickerViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if component == 0 {
            return minutes.count
        } else {
            return seconds.count
        }
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if component == 0 {
            return "\(minutes[row])"
        } else {
            return String(format: "%02d", seconds[row])
        }
    }

    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 44
    }

    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        return 100
    }
}
