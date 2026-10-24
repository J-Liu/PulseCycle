// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright 2026 Jia Liu
// Licensed under AGPL-3.0-or-later with an additional permission
// under Section 7. See LICENSE for details.

import UIKit

class ProfileListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var profiles: [WorkoutProfile] { ProfileManager.shared.profiles }

    var onSelect: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Profiles"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addProfile)
        )
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(dismissVC)
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

    @objc private func dismissVC() {
        dismiss(animated: true)
    }

    @objc private func addProfile() {
        let current = ProfileManager.shared.currentProfile
        _ = ProfileManager.shared.addProfile(copyFrom: current)
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return profiles.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        let profile = profiles[indexPath.row]
        cell.textLabel?.text = profile.name
        cell.detailTextLabel?.text = "\(profile.rounds) rounds • \(profile.workSeconds)s work • \(profile.restSeconds)s rest"
        cell.accessoryType = (indexPath.row == ProfileManager.shared.currentProfileIndex) ? .checkmark : .none
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        ProfileManager.shared.selectProfile(at: indexPath.row)
        onSelect?()
        dismiss(animated: true)
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return profiles.count > 1
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete && profiles.count > 1 {
            ProfileManager.shared.deleteProfile(at: indexPath.row)
            tableView.reloadData()
        }
    }
}
