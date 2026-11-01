#!/bin/bash
# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright 2026 Jia Liu
# Licensed under AGPL-3.0-or-later with an additional permission
# under Section 7. See LICENSE for details.

./build.sh

# Find the built app
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/PulseCycle-*/Build/Products/Debug-iphoneos/PulseCycle.app -maxdepth 0 2>/dev/null)

if [ -z "$APP_PATH" ]; then
    echo "Error: Could not find Lunapeek.app"
    exit 1
fi

echo "Installing: $APP_PATH"
xcrun devicectl device install app --device iPhone "$APP_PATH"
