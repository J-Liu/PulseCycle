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
    var prepareTime: Int
    var warmUpSeconds: Int
    var warmUpEnabled: Bool
    var coolDownSeconds: Int
    var coolDownEnabled: Bool
    var prepareCountingSoundEnabled: Bool
    var startSoundEnabled: Bool
    var endingNotifySoundEnabled: Bool
    var endSoundEnabled: Bool
    var voiceOutputEnabled: Bool
    var workColor: String
    var restColor: String
    var heartRateColor: String
    var prepareColor: String
    var warmUpColor: String
    var coolDownColor: String

    static var defaultProfiles: [WorkoutProfile] {
        [
            WorkoutProfile(
                id: UUID(),
                name: "Amateur Boxing",
                rounds: 4,
                workSeconds: 120,
                restSeconds: 60,
                prepareTime: 5,
                warmUpSeconds: 180,
                warmUpEnabled: false,
                coolDownSeconds: 180,
                coolDownEnabled: false,
                prepareCountingSoundEnabled: true,
                startSoundEnabled: true,
                endingNotifySoundEnabled: true,
                endSoundEnabled: true,
                voiceOutputEnabled: true,
                workColor: "#FF6B6B",
                restColor: "#E0E0E0",
                heartRateColor: "#FF8A80",
                prepareColor: "#FFAAAA",
                warmUpColor: "#FF8888",
                coolDownColor: "#E8A0A0"
            ),
            WorkoutProfile(
                id: UUID(),
                name: "MMA",
                rounds: 5,
                workSeconds: 300,
                restSeconds: 60,
                prepareTime: 5,
                warmUpSeconds: 300,
                warmUpEnabled: false,
                coolDownSeconds: 300,
                coolDownEnabled: false,
                prepareCountingSoundEnabled: true,
                startSoundEnabled: true,
                endingNotifySoundEnabled: true,
                endSoundEnabled: true,
                voiceOutputEnabled: true,
                workColor: "#FF6B6B",
                restColor: "#E0E0E0",
                heartRateColor: "#FF8A80",
                prepareColor: "#FFAAAA",
                warmUpColor: "#FF8888",
                coolDownColor: "#E8A0A0"
            ),
            WorkoutProfile(
                id: UUID(),
                name: "Classic Boxing",
                rounds: 12,
                workSeconds: 180,
                restSeconds: 60,
                prepareTime: 5,
                warmUpSeconds: 180,
                warmUpEnabled: false,
                coolDownSeconds: 180,
                coolDownEnabled: false,
                prepareCountingSoundEnabled: true,
                startSoundEnabled: true,
                endingNotifySoundEnabled: true,
                endSoundEnabled: true,
                voiceOutputEnabled: true,
                workColor: "#FF6B6B",
                restColor: "#E0E0E0",
                heartRateColor: "#FF8A80",
                prepareColor: "#FFAAAA",
                warmUpColor: "#FF8888",
                coolDownColor: "#E8A0A0"
            ),
            WorkoutProfile(
                id: UUID(),
                name: "Boxing Training",
                rounds: 3,
                workSeconds: 300,
                restSeconds: 60,
                prepareTime: 5,
                warmUpSeconds: 600,
                warmUpEnabled: true,
                coolDownSeconds: 600,
                coolDownEnabled: true,
                prepareCountingSoundEnabled: true,
                startSoundEnabled: true,
                endingNotifySoundEnabled: true,
                endSoundEnabled: true,
                voiceOutputEnabled: true,
                workColor: "#FF6B6B",
                restColor: "#E0E0E0",
                heartRateColor: "#FF8A80",
                prepareColor: "#FFAAAA",
                warmUpColor: "#FF8888",
                coolDownColor: "#E8A0A0"
            ),
            WorkoutProfile(
                id: UUID(),
                name: "Jump Rope",
                rounds: 5,
                workSeconds: 120,
                restSeconds: 60,
                prepareTime: 5,
                warmUpSeconds: 120,
                warmUpEnabled: false,
                coolDownSeconds: 120,
                coolDownEnabled: false,
                prepareCountingSoundEnabled: true,
                startSoundEnabled: true,
                endingNotifySoundEnabled: true,
                endSoundEnabled: true,
                voiceOutputEnabled: true,
                workColor: "#FF6B6B",
                restColor: "#E0E0E0",
                heartRateColor: "#FF8A80",
                prepareColor: "#FFAAAA",
                warmUpColor: "#FF8888",
                coolDownColor: "#E8A0A0"
            )
        ]
    }

    static var defaultProfile: WorkoutProfile {
        return defaultProfiles[0]
    }
}

class ProfileManager {
    static let shared = ProfileManager()

    private let userDefaultsKey = "workout_profiles"
    private let currentProfileIndexKey = "current_profile_index"
    private(set) var profiles: [WorkoutProfile]
    private(set) var currentProfileIndex: Int = 0 {
        didSet {
            UserDefaults.standard.set(currentProfileIndex, forKey: currentProfileIndexKey)
        }
    }

    var currentProfile: WorkoutProfile {
        profiles[currentProfileIndex]
    }

    private init() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([WorkoutProfile].self, from: data) {
            profiles = decoded
        } else {
            profiles = WorkoutProfile.defaultProfiles
        }

        // Restore last selected profile index
        currentProfileIndex = UserDefaults.standard.integer(forKey: currentProfileIndexKey)
        if currentProfileIndex >= profiles.count {
            currentProfileIndex = 0
        }
    }

    func save() {
        if let encoded = try? JSONEncoder().encode(profiles) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }

    func addProfile(copyFrom profile: WorkoutProfile, name: String? = nil) -> WorkoutProfile {
        var newProfile = profile
        newProfile.id = UUID()
        newProfile.name = name ?? "\(profile.name) Copy"
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
        // currentProfileIndex didSet will automatically save to UserDefaults
    }

    func selectProfile(at index: Int) {
        guard index < profiles.count else { return }
        currentProfileIndex = index
        // currentProfileIndex didSet will automatically save to UserDefaults
    }

    func updateProfile(_ profile: WorkoutProfile) {
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[index] = profile
            save()
        }
    }
}
