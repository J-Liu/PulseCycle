// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright 2026 Jia Liu

import CoreBluetooth

protocol HeartRateMonitorDelegate: AnyObject {
    func heartRateMonitor(_ monitor: HeartRateMonitor, didUpdateHeartRate bpm: Int)
    func heartRateMonitor(_ monitor: HeartRateMonitor, didChangeState state: HeartRateMonitorState)
    func heartRateMonitor(_ monitor: HeartRateMonitor, didFailWithError error: Error)
}

enum HeartRateMonitorState {
    case idle
    case scanning
    case connecting
    case connected
    case disconnected
}

class HeartRateMonitor: NSObject {
    weak var delegate: HeartRateMonitorDelegate?

    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    private var heartRateCharacteristic: CBCharacteristic?
    private let queue = DispatchQueue(label: "com.pulsecycle.bluetooth")

    private let heartRateServiceUUID = CBUUID(string: "180D")
    private let heartRateMeasurementUUID = CBUUID(string: "2A37")

    private var scanTimer: DispatchSourceTimer?

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: queue)
    }

    func startScanning() {
        guard centralManager.state == .poweredOn else {
            delegate?.heartRateMonitor(self, didChangeState: .disconnected)
            return
        }

        delegate?.heartRateMonitor(self, didChangeState: .scanning)
        centralManager.scanForPeripherals(withServices: [heartRateServiceUUID], options: nil)
        startScanTimeout()
    }

    func stopScanning() {
        centralManager.stopScan()
        scanTimer?.cancel()
        scanTimer = nil
    }

    func disconnect() {
        if let peripheral = connectedPeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
        connectedPeripheral = nil
        heartRateCharacteristic = nil
        delegate?.heartRateMonitor(self, didChangeState: .disconnected)
    }

    private func startScanTimeout() {
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + 30)
        timer.setEventHandler { [weak self] in
            guard let self = self else { return }
            self.stopScanning()
            if self.connectedPeripheral == nil {
                self.delegate?.heartRateMonitor(self, didChangeState: .disconnected)
            }
        }
        timer.resume()
        scanTimer = timer
    }

    private func parseHeartRate(_ data: Data) -> Int? {
        guard !data.isEmpty else { return nil }

        let firstByte = data[0]
        let isUInt16 = (firstByte & 0x01) != 0

        if isUInt16 {
            guard data.count >= 3 else { return nil }
            let bpm = UInt16(data[1]) | (UInt16(data[2]) << 8)
            return Int(bpm)
        } else {
            guard data.count >= 2 else { return nil }
            return Int(data[1])
        }
    }
}

extension HeartRateMonitor: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state != .poweredOn {
            delegate?.heartRateMonitor(self, didChangeState: .disconnected)
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        stopScanning()
        connectedPeripheral = peripheral
        peripheral.delegate = self
        delegate?.heartRateMonitor(self, didChangeState: .connecting)
        central.connect(peripheral, options: nil)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        delegate?.heartRateMonitor(self, didChangeState: .connected)
        peripheral.discoverServices([heartRateServiceUUID])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if let error = error {
            delegate?.heartRateMonitor(self, didFailWithError: error)
        }
        connectedPeripheral = nil
        delegate?.heartRateMonitor(self, didChangeState: .disconnected)
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        connectedPeripheral = nil
        heartRateCharacteristic = nil
        delegate?.heartRateMonitor(self, didChangeState: .disconnected)

        if error != nil {
            startScanning()
        }
    }
}

extension HeartRateMonitor: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            delegate?.heartRateMonitor(self, didFailWithError: error!)
            return
        }

        if let service = peripheral.services?.first(where: { $0.uuid == heartRateServiceUUID }) {
            peripheral.discoverCharacteristics([heartRateMeasurementUUID], for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else {
            delegate?.heartRateMonitor(self, didFailWithError: error!)
            return
        }

        if let characteristic = service.characteristics?.first(where: { $0.uuid == heartRateMeasurementUUID }) {
            heartRateCharacteristic = characteristic
            peripheral.setNotifyValue(true, for: characteristic)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            delegate?.heartRateMonitor(self, didFailWithError: error!)
            return
        }

        if let data = characteristic.value, let bpm = parseHeartRate(data) {
            delegate?.heartRateMonitor(self, didUpdateHeartRate: bpm)
        }
    }
}
