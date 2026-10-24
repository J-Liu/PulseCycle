// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright 2026 Jia Liu
// Licensed under AGPL-3.0-or-later with an additional permission
// under Section 7. See LICENSE for details.

import Foundation

enum IntervalPhase: String {
    case warmUp = "WARM UP"
    case work = "WORK"
    case rest = "REST"
    case coolDown = "COOL DOWN"
    case finished = "FINISHED"
}
