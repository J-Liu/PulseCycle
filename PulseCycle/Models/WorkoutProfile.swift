// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright 2026 Jia Liu
// Licensed under AGPL-3.0-or-later with an additional permission
// under Section 7. See LICENSE for details.

import Foundation

struct WorkoutProfile: Codable, Identifiable {
    var id: UUID
    var name: String
    var rounds: Int
    var workSeconds: Int
    var restSeconds: Int
    var warningSeconds: Int
    var warmUpSeconds: Int
    var warmUpEnabled: Bool
    var coolDownSeconds: Int
    var coolDownEnabled: Bool
    var startSoundEnabled: Bool
    var endSoundEnabled: Bool
    var warningSoundEnabled: Bool
    var workColor: String
    var restColor: String
    var heartRateColor: String

    static var defaultProfile: WorkoutProfile {
        WorkoutProfile(
            id: UUID(),
            name: "Default",
            rounds: 8,
            workSeconds: 30,
            restSeconds: 15,
            warningSeconds: 3,
            warmUpSeconds: 60,
            warmUpEnabled: true,
            coolDownSeconds: 60,
            coolDownEnabled: true,
            startSoundEnabled: true,
            endSoundEnabled: true,
            warningSoundEnabled: true,
            workColor: "#FF6B6B",
            restColor: "#E0E0E0",
            heartRateColor: "#FF8A80"
        )
    }
}

class ProfileManager {
    static let shared = ProfileManager()

    private let userDefaultsKey = "workout_profiles"
    private(set) var profiles: [WorkoutProfile]
    private(set) var currentProfileIndex: Int = 0

    var currentProfile: WorkoutProfile {
        profiles[currentProfileIndex]
    }

    private init() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([WorkoutProfile].self, from: data) {
            profiles = decoded
        } else {
            profiles = [WorkoutProfile.defaultProfile]
        }
    }

    func save() {
        if let encoded = try? JSONEncoder().encode(profiles) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }

    func addProfile(copyFrom profile: WorkoutProfile) -> WorkoutProfile {
        var newProfile = profile
        newProfile.id = UUID()
        newProfile.name = "\(profile.name) Copy"
        profiles.append(newProfile)
        save()
        return newProfile
    }

    func deleteProfile(at index: Int) {
        guard profiles.count > 1, index < profiles.count else { return }
        profiles.remove(at: index)
        if currentProfileIndex >= profiles.count {
            currentProfileIndex = profiles.count - 1
        }
        save()
    }

    func selectProfile(at index: Int) {
        guard index < profiles.count else { return }
        currentProfileIndex = index
        save()
    }

    func updateProfile(_ profile: WorkoutProfile) {
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[index] = profile
            save()
        }
    }
}
