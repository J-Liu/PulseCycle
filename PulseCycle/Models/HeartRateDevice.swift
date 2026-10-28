// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright 2026 Jia Liu
// Licensed under AGPL-3.0-or-later with an additional permission
// under Section 7. See LICENSE for details.

import Foundation
import CoreBluetooth

struct HeartRateDevice: Codable, Equatable {
    let uuid: String
    let name: String

    var identifier: UUID {
        UUID(uuidString: uuid) ?? UUID()
    }
}

class DeviceManager {
    static let shared = DeviceManager()

    private let devicesKey = "saved_heart_rate_devices"
    private let defaultDeviceKey = "default_heart_rate_device"

    private(set) var devices: [HeartRateDevice] = []
    private(set) var defaultDeviceUUID: String?

    private init() {
        loadDevices()
        loadDefaultDevice()
    }

    private func loadDevices() {
        if let data = UserDefaults.standard.data(forKey: devicesKey),
           let decoded = try? JSONDecoder().decode([HeartRateDevice].self, from: data) {
            devices = decoded
        }
    }

    private func loadDefaultDevice() {
        defaultDeviceUUID = UserDefaults.standard.string(forKey: defaultDeviceKey)
    }

    func saveDevice(_ peripheral: CBPeripheral) {
        let uuid = peripheral.identifier.uuidString
        let name = peripheral.name ?? "Unknown Device"

        // Check if device already exists
        if let index = devices.firstIndex(where: { $0.uuid == uuid }) {
            // Update name if changed
            if devices[index].name != name {
                devices[index] = HeartRateDevice(uuid: uuid, name: name)
                saveDevices()
            }
        } else {
            // Add new device
            devices.append(HeartRateDevice(uuid: uuid, name: name))
            saveDevices()

            // Set as default if it's the first device
            if devices.count == 1 {
                setDefaultDevice(uuid: uuid)
            }
        }
    }

    func removeDevice(at index: Int) {
        guard index < devices.count else { return }
        let device = devices[index]
        devices.remove(at: index)
        saveDevices()

        // If removed device was default, clear default
        if defaultDeviceUUID == device.uuid {
            defaultDeviceUUID = nil
            UserDefaults.standard.removeObject(forKey: defaultDeviceKey)

            // Set first remaining device as default if exists
            if let firstDevice = devices.first {
                setDefaultDevice(uuid: firstDevice.uuid)
            }
        }
    }

    func setDefaultDevice(uuid: String) {
        defaultDeviceUUID = uuid
        UserDefaults.standard.set(uuid, forKey: defaultDeviceKey)
    }

    func getDefaultDevice() -> HeartRateDevice? {
        guard let uuid = defaultDeviceUUID else { return nil }
        return devices.first { $0.uuid == uuid }
    }

    func getDevice(byUUID uuid: String) -> HeartRateDevice? {
        return devices.first { $0.uuid == uuid }
    }

    private func saveDevices() {
        if let encoded = try? JSONEncoder().encode(devices) {
            UserDefaults.standard.set(encoded, forKey: devicesKey)
        }
    }
}
