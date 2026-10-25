// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright 2026 Jia Liu
// Licensed under AGPL-3.0-or-later with an additional permission
// under Section 7. See LICENSE for details.

import UIKit

class SettingsViewController: UIViewController {
    var onSave: (() -> Void)?

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var currentColorRow = 0
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
        title = L("Settings")
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
        case .profile: return 7
        case .sound: return 4
        case .color: return 3
        case .misc: return 2
        case .none: return 0
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section) {
        case .profile: return L("Profile")
        case .sound: return L("Sound")
        case .color: return L("Color")
        case .misc: return L("Misc")
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
            cell.textLabel?.text = L("Profile Name")
            cell.detailTextLabel?.text = profile.name
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
        case 1:
            cell.textLabel?.text = L("Rounds")
            let stepper = UIStepper()
            stepper.minimumValue = 1
            stepper.maximumValue = 99
            stepper.value = Double(profile.rounds)
            stepper.addTarget(self, action: #selector(roundsChanged(_:)), for: .valueChanged)
            cell.accessoryView = stepper
            cell.detailTextLabel?.text = "\(profile.rounds)"
        case 2:
            cell.textLabel?.text = L("Work (seconds)")
            let stepper = UIStepper()
            stepper.minimumValue = 5
            stepper.maximumValue = 600
            stepper.stepValue = 5
            stepper.value = Double(profile.workSeconds)
            stepper.addTarget(self, action: #selector(workChanged(_:)), for: .valueChanged)
            cell.accessoryView = stepper
            cell.detailTextLabel?.text = "\(profile.workSeconds)"
        case 3:
            cell.textLabel?.text = L("Rest (seconds)")
            let stepper = UIStepper()
            stepper.minimumValue = 5
            stepper.maximumValue = 300
            stepper.stepValue = 5
            stepper.value = Double(profile.restSeconds)
            stepper.addTarget(self, action: #selector(restChanged(_:)), for: .valueChanged)
            cell.accessoryView = stepper
            cell.detailTextLabel?.text = "\(profile.restSeconds)"
        case 4:
            cell.textLabel?.text = L("Warm-up")
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
        case 5:
            cell.textLabel?.text = L("Cool-down")
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
        case 6:
            cell.textLabel?.text = L("Prepare time")
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
            cell.textLabel?.text = L("Prepare counting sound")
            switch_.isOn = profile.prepareCountingSoundEnabled
            switch_.addTarget(self, action: #selector(prepareCountingSoundToggled(_:)), for: .valueChanged)
        case 1:
            cell.textLabel?.text = L("Start sound")
            switch_.isOn = profile.startSoundEnabled
            switch_.addTarget(self, action: #selector(startSoundToggled(_:)), for: .valueChanged)
        case 2:
            cell.textLabel?.text = L("Ending notify sound")
            switch_.isOn = profile.endingNotifySoundEnabled
            switch_.addTarget(self, action: #selector(endingNotifySoundToggled(_:)), for: .valueChanged)
        case 3:
            cell.textLabel?.text = L("End sound")
            switch_.isOn = profile.endSoundEnabled
            switch_.addTarget(self, action: #selector(endSoundToggled(_:)), for: .valueChanged)
        default:
            break
        }
        cell.accessoryView = switch_
    }

    private func configureColorCell(_ cell: UITableViewCell, row: Int) {
        let names = [L("Work"), L("Rest"), L("Heart Rate")]
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

        // Add long press gesture for reset
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleColorLongPress(_:)))
        longPress.minimumPressDuration = 0.5
        cell.addGestureRecognizer(longPress)
        cell.tag = row
    }

    private func configureMiscCell(_ cell: UITableViewCell, row: Int) {
        switch row {
        case 0:
            cell.textLabel?.text = L("Language")
            let currentLang = LanguageManager.shared.currentLanguage
            cell.detailTextLabel?.text = currentLang.displayName
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
        case 1:
            cell.textLabel?.text = L("Voice input")
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

    @objc private func prepareCountingSoundToggled(_ switch_: UISwitch) {
        var p = profile
        p.prepareCountingSoundEnabled = switch_.isOn
        ProfileManager.shared.updateProfile(p)
    }

    @objc private func startSoundToggled(_ switch_: UISwitch) {
        var p = profile
        p.startSoundEnabled = switch_.isOn
        ProfileManager.shared.updateProfile(p)
    }

    @objc private func endingNotifySoundToggled(_ switch_: UISwitch) {
        var p = profile
        p.endingNotifySoundEnabled = switch_.isOn
        ProfileManager.shared.updateProfile(p)
    }

    @objc private func endSoundToggled(_ switch_: UISwitch) {
        var p = profile
        p.endSoundEnabled = switch_.isOn
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
        } else if indexPath.section == Section.misc.rawValue && indexPath.row == 0 {
            showLanguagePicker()
        } else if indexPath.section == Section.color.rawValue {
            showColorPicker(for: indexPath.row)
        }
    }

    private func showLanguagePicker() {
        let alert = UIAlertController(title: L("Language"), message: nil, preferredStyle: .actionSheet)

        for language in Language.allCases {
            let action = UIAlertAction(title: language.displayName, style: .default) { [weak self] _ in
                LanguageManager.shared.applyLanguage(language)
                self?.tableView.reloadData()
                self?.onSave?()
            }
            if language == LanguageManager.shared.currentLanguage {
                action.setValue(true, forKey: "checked")
            }
            alert.addAction(action)
        }

        alert.addAction(UIAlertAction(title: L("Cancel"), style: .cancel))

        if let popover = alert.popoverPresentationController {
            popover.sourceView = tableView
            popover.sourceRect = tableView.cellForRow(at: IndexPath(row: 0, section: Section.misc.rawValue))?.frame ?? .zero
        }

        present(alert, animated: true)
    }

    private func showColorPicker(for row: Int) {
        currentColorRow = row
        let colorPicker = UIColorPickerViewController()
        colorPicker.delegate = self

        let currentColors = [profile.workColor, profile.restColor, profile.heartRateColor]
        colorPicker.selectedColor = UIColor(hex: currentColors[row]) ?? .white

        // Add toolbar with reset button
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let resetButton = UIBarButtonItem(title: L("Reset to Default"), style: .plain, target: self, action: #selector(resetColorFromPicker))
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissColorPicker))
        toolbar.items = [resetButton, flexibleSpace, doneButton]

        colorPicker.additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 0, bottom: 44, right: 0)
        colorPicker.view.addSubview(toolbar)
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            toolbar.leadingAnchor.constraint(equalTo: colorPicker.view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: colorPicker.view.trailingAnchor),
            toolbar.bottomAnchor.constraint(equalTo: colorPicker.view.safeAreaLayoutGuide.bottomAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: 44)
        ])

        present(colorPicker, animated: true)
    }

    @objc private func resetColorFromPicker() {
        resetColor(for: currentColorRow)
        if let colorPicker = presentedViewController as? UIColorPickerViewController {
            let currentColors = [profile.workColor, profile.restColor, profile.heartRateColor]
            colorPicker.selectedColor = UIColor(hex: currentColors[currentColorRow]) ?? .white
        }
    }

    @objc private func dismissColorPicker() {
        dismiss(animated: true)
    }

    private func resetColor(for row: Int) {
        var p = profile
        let defaultColors = ["#FF6B6B", "#E0E0E0", "#FF8A80"]

        switch row {
        case 0:
            p.workColor = defaultColors[0]
        case 1:
            p.restColor = defaultColors[1]
        case 2:
            p.heartRateColor = defaultColors[2]
        default:
            break
        }

        ProfileManager.shared.updateProfile(p)
        tableView.reloadRows(at: [IndexPath(row: row, section: Section.color.rawValue)], with: .none)
        onSave?()
    }

    @objc private func handleColorLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        guard let cell = gesture.view as? UITableViewCell else { return }

        let row = cell.tag
        let colorNames = [L("Work"), L("Rest"), L("Heart Rate")]
        let alert = UIAlertController(title: colorNames[row], message: nil, preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: L("Reset to Default"), style: .default) { [weak self] _ in
            self?.resetColor(for: row)
        })

        alert.addAction(UIAlertAction(title: L("Cancel"), style: .cancel))

        if let popover = alert.popoverPresentationController {
            popover.sourceView = cell
            popover.sourceRect = cell.bounds
        }

        present(alert, animated: true)
    }
}

extension SettingsViewController: UIColorPickerViewControllerDelegate {
    func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
        let row = currentColorRow
        let hex = viewController.selectedColor.toHexString()

        var p = profile
        switch row {
        case 0:
            p.workColor = hex
        case 1:
            p.restColor = hex
        case 2:
            p.heartRateColor = hex
        default:
            break
        }

        ProfileManager.shared.updateProfile(p)
        tableView.reloadRows(at: [IndexPath(row: row, section: Section.color.rawValue)], with: .none)
        onSave?()
    }
}
