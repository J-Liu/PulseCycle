// SPDX-FileCopyrightText: 2026 Jia Liu
// SPDX-License-Identifier: Apache-2.0

import UIKit

class SettingsViewController: UIViewController {
    var onSave: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        view.backgroundColor = .systemGroupedBackground

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(done)
        )
    }

    @objc private func done() {
        onSave?()
        dismiss(animated: true)
    }
}
