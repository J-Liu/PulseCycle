#!/bin/bash
# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright 2026 Jia Liu
# Licensed under AGPL-3.0-or-later with an additional permission
# under Section 7. See LICENSE for details.

xcodebuild -project PulseCycle.xcodeproj \
  -scheme PulseCycle \
  -destination 'platform=iOS,name=iPhone' \
  -allowProvisioningUpdates \
  build
