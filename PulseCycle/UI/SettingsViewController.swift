// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright 2026 Jia Liu
// Licensed under AGPL-3.0-or-later with an additional permission
// under Section 7. See LICENSE for details.

import UIKit

class SettingsViewController: UIViewController {
    var onSave: (() -> Void)?

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var profile: WorkoutProfile {
        ProfileManager.shared.currentProfile
    }

    private enum Section: Int, CaseIterable {
        case profile
        case sound
        case color
        case misc
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        view.backgroundColor = .systemGroupedBackground

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(done)
        )

        tableView.delegate = self
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    @objc private func done() {
        onSave?()
        dismiss(animated: true)
    }
}

extension SettingsViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section) {
        case .profile: return 8
        case .sound: return 3
        case .color: return 3
        case .misc: return 2
        case .none: return 0
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section) {
        case .profile: return "Profile"
        case .sound: return "Sound"
        case .color: return "Color"
        case .misc: return "Misc"
        case .none: return nil
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        cell.selectionStyle = .none

        switch Section(rawValue: indexPath.section) {
        case .profile:
            configureProfileCell(cell, row: indexPath.row)
        case .sound:
            configureSoundCell(cell, row: indexPath.row)
        case .color:
            configureColorCell(cell, row: indexPath.row)
        case .misc:
            configureMiscCell(cell, row: indexPath.row)
        case .none:
            break
        }

        return cell
    }

    private func configureProfileCell(_ cell: UITableViewCell, row: Int) {
        switch row {
        case 0:
            cell.textLabel?.text = "Profile Name"
            cell.detailTextLabel?.text = profile.name
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
        case 1:
            cell.textLabel?.text = "Rounds"
            let stepper = UIStepper()
            stepper.minimumValue = 1
            stepper.maximumValue = 99
            stepper.value = Double(profile.rounds)
            stepper.addTarget(self, action: #selector(roundsChanged(_:)), for: .valueChanged)
            cell.accessoryView = stepper
            cell.detailTextLabel?.text = "\(profile.rounds)"
        case 2:
            cell.textLabel?.text = "Work (seconds)"
            let stepper = UIStepper()
            stepper.minimumValue = 5
            stepper.maximumValue = 600
            stepper.stepValue = 5
            stepper.value = Double(profile.workSeconds)
            stepper.addTarget(self, action: #selector(workChanged(_:)), for: .valueChanged)
            cell.accessoryView = stepper
            cell.detailTextLabel?.text = "\(profile.workSeconds)"
        case 3:
            cell.textLabel?.text = "Rest (seconds)"
            let stepper = UIStepper()
            stepper.minimumValue = 5
            stepper.maximumValue = 300
            stepper.stepValue = 5
            stepper.value = Double(profile.restSeconds)
            stepper.addTarget(self, action: #selector(restChanged(_:)), for: .valueChanged)
            cell.accessoryView = stepper
            cell.detailTextLabel?.text = "\(profile.restSeconds)"
        case 4:
            cell.textLabel?.text = "Warning before round end"
            let stepper = UIStepper()
            stepper.minimumValue = 0
            stepper.maximumValue = 30
            stepper.value = Double(profile.warningSeconds)
            stepper.addTarget(self, action: #selector(warningChanged(_:)), for: .valueChanged)
            cell.accessoryView = stepper
            cell.detailTextLabel?.text = "\(profile.warningSeconds)s"
        case 5:
            cell.textLabel?.text = "Warm-up"
            let stack = UIStackView()
            let switch_ = UISwitch()
            switch_.isOn = profile.warmUpEnabled
            switch_.addTarget(self, action: #selector(warmUpToggled(_:)), for: .valueChanged)
            let label = UILabel()
            label.text = "\(profile.warmUpSeconds)s"
            label.textColor = .secondaryLabel
            stack.axis = .horizontal
            stack.spacing = 8
            stack.addArrangedSubview(label)
            stack.addArrangedSubview(switch_)
            cell.accessoryView = stack
        case 6:
            cell.textLabel?.text = "Cool-down"
            let stack = UIStackView()
            let switch_ = UISwitch()
            switch_.isOn = profile.coolDownEnabled
            switch_.addTarget(self, action: #selector(coolDownToggled(_:)), for: .valueChanged)
            let label = UILabel()
            label.text = "\(profile.coolDownSeconds)s"
            label.textColor = .secondaryLabel
            stack.axis = .horizontal
            stack.spacing = 8
            stack.addArrangedSubview(label)
            stack.addArrangedSubview(switch_)
            cell.accessoryView = stack
        case 7:
            cell.textLabel?.text = "Prepare time"
            let stepper = UIStepper()
            stepper.minimumValue = 0
            stepper.maximumValue = 30
            stepper.value = Double(profile.warmUpSeconds)
            stepper.addTarget(self, action: #selector(prepareChanged(_:)), for: .valueChanged)
            cell.accessoryView = stepper
            cell.detailTextLabel?.text = "\(profile.warmUpSeconds)s"
        default:
            break
        }
    }

    private func configureSoundCell(_ cell: UITableViewCell, row: Int) {
        let switch_ = UISwitch()
        switch row {
        case 0:
            cell.textLabel?.text = "Start sound"
            switch_.isOn = profile.startSoundEnabled
            switch_.addTarget(self, action: #selector(startSoundToggled(_:)), for: .valueChanged)
        case 1:
            cell.textLabel?.text = "End sound"
            switch_.isOn = profile.endSoundEnabled
            switch_.addTarget(self, action: #selector(endSoundToggled(_:)), for: .valueChanged)
        case 2:
            cell.textLabel?.text = "Warning sound"
            switch_.isOn = profile.warningSoundEnabled
            switch_.addTarget(self, action: #selector(warningSoundToggled(_:)), for: .valueChanged)
        default:
            break
        }
        cell.accessoryView = switch_
    }

    private func configureColorCell(_ cell: UITableViewCell, row: Int) {
        let colors = ["#FF6B6B", "#E0E0E0", "#FF8A80"]
        let names = ["Work", "Rest", "Heart Rate"]
        let currentColors = [profile.workColor, profile.restColor, profile.heartRateColor]

        cell.textLabel?.text = names[row]

        let colorView = UIView()
        colorView.backgroundColor = UIColor(hex: currentColors[row])
        colorView.layer.cornerRadius = 12
        colorView.layer.borderWidth = 1
        colorView.layer.borderColor = UIColor.systemGray4.cgColor
        colorView.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
        cell.accessoryView = colorView

        cell.selectionStyle = .default
        cell.accessoryType = .disclosureIndicator
    }

    private func configureMiscCell(_ cell: UITableViewCell, row: Int) {
        switch row {
        case 0:
            cell.textLabel?.text = "Language"
            cell.detailTextLabel?.text = "System"
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
        case 1:
            cell.textLabel?.text = "Voice input"
            let switch_ = UISwitch()
            switch_.isOn = false
            cell.accessoryView = switch_
        default:
            break
        }
    }

    @objc private func roundsChanged(_ stepper: UIStepper) {
        var p = profile
        p.rounds = Int(stepper.value)
        ProfileManager.shared.updateProfile(p)
        tableView.reloadRows(at: [IndexPath(row: 1, section: 0)], with: .none)
    }

    @objc private func workChanged(_ stepper: UIStepper) {
        var p = profile
        p.workSeconds = Int(stepper.value)
        ProfileManager.shared.updateProfile(p)
        tableView.reloadRows(at: [IndexPath(row: 2, section: 0)], with: .none)
    }

    @objc private func restChanged(_ stepper: UIStepper) {
        var p = profile
        p.restSeconds = Int(stepper.value)
        ProfileManager.shared.updateProfile(p)
        tableView.reloadRows(at: [IndexPath(row: 3, section: 0)], with: .none)
    }

    @objc private func warningChanged(_ stepper: UIStepper) {
        var p = profile
        p.warningSeconds = Int(stepper.value)
        ProfileManager.shared.updateProfile(p)
        tableView.reloadRows(at: [IndexPath(row: 4, section: 0)], with: .none)
    }

    @objc private func warmUpToggled(_ switch_: UISwitch) {
        var p = profile
        p.warmUpEnabled = switch_.isOn
        ProfileManager.shared.updateProfile(p)
    }

    @objc private func coolDownToggled(_ switch_: UISwitch) {
        var p = profile
        p.coolDownEnabled = switch_.isOn
        ProfileManager.shared.updateProfile(p)
    }

    @objc private func prepareChanged(_ stepper: UIStepper) {
        var p = profile
        p.warmUpSeconds = Int(stepper.value)
        ProfileManager.shared.updateProfile(p)
        tableView.reloadRows(at: [IndexPath(row: 5, section: 0), IndexPath(row: 7, section: 0)], with: .none)
    }

    @objc private func startSoundToggled(_ switch_: UISwitch) {
        var p = profile
        p.startSoundEnabled = switch_.isOn
        ProfileManager.shared.updateProfile(p)
    }

    @objc private func endSoundToggled(_ switch_: UISwitch) {
        var p = profile
        p.endSoundEnabled = switch_.isOn
        ProfileManager.shared.updateProfile(p)
    }

    @objc private func warningSoundToggled(_ switch_: UISwitch) {
        var p = profile
        p.warningSoundEnabled = switch_.isOn
        ProfileManager.shared.updateProfile(p)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if indexPath.section == Section.profile.rawValue && indexPath.row == 0 {
            let vc = ProfileListViewController()
            vc.onSelect = { [weak self] in
                self?.tableView.reloadData()
                self?.onSave?()
            }
            let nav = UINavigationController(rootViewController: vc)
            present(nav, animated: true)
        }
    }
}
