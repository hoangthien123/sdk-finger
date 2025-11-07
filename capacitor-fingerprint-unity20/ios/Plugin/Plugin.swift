import Foundation
import Capacitor
import CoreBluetooth

@objc(CapacitorFingerprintPlugin)
public class CapacitorFingerprintPlugin: CAPPlugin {
    private let ble = BLEManager()

    public override func load() {
        ble.onDevice = { [weak self] p, rssi in
            self?.notifyListeners("deviceDiscovered", data: [
                "id": p.identifier.uuidString,
                "name": p.name ?? "",
                "rssi": rssi?.intValue ?? 0
            ])
        }
        ble.onConnected = { [weak self] p in
            self?.notifyListeners("connected", data: ["deviceId": p.identifier.uuidString])
        }
        ble.onDisconnected = { [weak self] p, _ in
            self?.notifyListeners("disconnected", data: ["deviceId": p.identifier.uuidString])
        }
        ble.onData = { [weak self] data in
            let bytes = [UInt8](data)
            let hex = bytes.map { String(format: "%02X", $0) }.joined()
            self?.notifyListeners("data", data: ["hex": hex, "bytes": bytes])
        }
        ble.onError = { [weak self] msg in
            self?.notifyListeners("error", data: ["message": msg])
        }
    }

    @objc func initialize(_ call: CAPPluginCall) {
        guard let serviceUUID = call.getString("serviceUUID"),
              let writeUUID = call.getString("writeCharacteristicUUID"),
              let notifyUUID = call.getString("notifyCharacteristicUUID") else {
            call.reject("Missing UUIDs: serviceUUID, writeCharacteristicUUID, notifyCharacteristicUUID")
            return
        }
        let scanDuration = call.getInt("scanDurationMs") ?? 8000
        ble.setConfig(serviceUUID: serviceUUID, writeChar: writeUUID, notifyChar: notifyUUID, scanDurationMs: scanDuration)
        call.resolve()
    }

    @objc func scan(_ call: CAPPluginCall) {
        guard ble.isPoweredOn() else {
            call.reject("Bluetooth is not powered on")
            return
        }
        ble.startScan()
        let duration = ble.config?.scanDuration ?? 8.0
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.ble.stopScan()
            let devices: [[String: Any]] = self?.ble.discovered.values.map { p in
                [
                    "id": p.identifier.uuidString,
                    "name": p.name ?? ""
                ]
            } ?? []
            call.resolve(["devices": devices])
        }
    }

    @objc func stopScan(_ call: CAPPluginCall) {
        ble.stopScan()
        call.resolve()
    }

    @objc func connect(_ call: CAPPluginCall) {
        guard let deviceId = call.getString("deviceId") else {
            call.reject("deviceId is required")
            return
        }
        let timeoutMs = call.getInt("timeoutMs") ?? 8000
        ble.connect(id: deviceId, timeout: TimeInterval(timeoutMs) / 1000.0)
        call.resolve()
    }

    @objc func disconnect(_ call: CAPPluginCall) {
        ble.disconnect()
        call.resolve()
    }

    @objc func sendCommand(_ call: CAPPluginCall) {
        guard let hex = call.getString("hex") else {
            call.reject("hex is required")
            return
        }
        let frame = call.getBool("frame") ?? false
        var bytes = Hex.toBytes(hex)
        if frame {
            bytes = CommandCodec.frame(bytes)
        }
        ble.send(bytes: bytes)
        call.resolve(["ok": true])
    }
}