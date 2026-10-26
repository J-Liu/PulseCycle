// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright 2026 Jia Liu
// Licensed under AGPL-3.0-or-later with an additional permission
// under Section 7. See LICENSE for details.

import Foundation

struct PhaseItem {
    let phase: IntervalPhase
    let duration: Int
    let color: String
    let startSound: String?
    let endSound: String?
    let tickSound: String?
    let warningAtSeconds: Int?  // 在剩余多少秒时播放警告音
    let warningSound: String?

    static func warmUp(_ profile: WorkoutProfile) -> PhaseItem {
        return PhaseItem(
            phase: .warmUp,
            duration: profile.warmUpSeconds,
            color: profile.warmUpColor,
            startSound: profile.startSoundEnabled ? "boxing-bell-1" : nil,
            endSound: nil,  // warm-up结束后立即进入正式回合
            tickSound: nil,
            warningAtSeconds: nil,
            warningSound: nil
        )
    }

    static func work(_ profile: WorkoutProfile) -> PhaseItem {
        return PhaseItem(
            phase: .work,
            duration: profile.workSeconds,
            color: profile.workColor,
            startSound: profile.startSoundEnabled ? "boxing-bell-1" : nil,
            endSound: profile.endSoundEnabled ? "boxing-bell-3" : nil,
            tickSound: nil,
            warningAtSeconds: profile.workSeconds >= 15 ? 10 : nil,
            warningSound: profile.endingNotifySoundEnabled ? "boxing-bell-2" : nil
        )
    }

    static func rest(_ profile: WorkoutProfile) -> PhaseItem {
        return PhaseItem(
            phase: .rest,
            duration: profile.restSeconds,
            color: profile.restColor,
            startSound: nil,  // rest 开始时不播放声音
            endSound: nil,    // rest 结束时不播放声音
            tickSound: nil,
            warningAtSeconds: nil,  // rest 不播放警告音
            warningSound: nil
        )
    }

    static func coolDown(_ profile: WorkoutProfile) -> PhaseItem {
        return PhaseItem(
            phase: .coolDown,
            duration: profile.coolDownSeconds,
            color: profile.coolDownColor,
            startSound: nil,  // cool-down紧接着正式回合结束
            endSound: profile.endSoundEnabled ? "boxing-bell-3" : nil,
            tickSound: nil,
            warningAtSeconds: profile.coolDownSeconds >= 15 && profile.endingNotifySoundEnabled ? 10 : nil,
            warningSound: profile.endingNotifySoundEnabled ? "boxing-bell-2" : nil
        )
    }
}

class PhaseSequenceBuilder {
    static func build(from profile: WorkoutProfile) -> [PhaseItem] {
        var items: [PhaseItem] = []

        // Warm-up
        if profile.warmUpEnabled {
            items.append(.warmUp(profile))
        }

        // Work/Rest rounds
        for _ in 0..<profile.rounds {
            items.append(.work(profile))
            items.append(.rest(profile))
        }

        // Cool-down
        if profile.coolDownEnabled {
            items.append(.coolDown(profile))
        }

        return items
    }
}
