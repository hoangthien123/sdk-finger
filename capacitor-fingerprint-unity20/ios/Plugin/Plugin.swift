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
                "name": p.name ?? NSNull(),
                "rssi": rssi?.intValue ?? NSNull()
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
            self?.notifyListeners("data", data: [
                "hex": Hex.fromBytes(bytes),
                "bytes": bytes
            ])
        }
        ble.onError = { [weak self] msg in
            self?.notifyListeners("error", data: ["message": msg])
        }
    }

    @objc func initialize(_ call: CAPPluginCall) {
        guard let serviceUUID = call.getString("serviceUUID"),
              let writeUUID = call.getString("writeCharacteristicUUID"),
              let notifyUUID = call.getString("notifyCharacteristicUUID") else {
            call.reject("Missing UUIDs")
            return
        }
        let scanDuration = call.getInt("scanDurationMs") ?? 8000
        ble.setConfig(serviceUUID: serviceUUID,
                      writeChar: writeUUID,
                      notifyChar: notifyUUID,
                      scanDurationMs: scanDuration)
        call.resolve()
    }

    @objc func scan(_ call: CAPPluginCall) {
        guard ble.isPoweredOn() else {
            call.reject("Bluetooth not powered on")
            return
        }
        ble.startScan()
        let duration = ble.config?.scanDuration ?? 8.0
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.ble.stopScan()
            let devices = self?.ble.discovered.values.map { p in
                [
                    "id": p.identifier.uuidString,
                    "name": p.name ?? NSNull()
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
            call.reject("deviceId required")
            return
        }
        let timeoutMs = call.getInt("timeoutMs") ?? 8000
        ble.connect(id: deviceId, timeout: TimeInterval(timeoutMs)/1000.0)
        call.resolve()
    }

    @objc func disconnect(_ call: CAPPluginCall) {
        ble.disconnect()
        call.resolve()
    }

    @objc func sendCommand(_ call: CAPPluginCall) {
        guard let hex = call.getString("hex") else {
            call.reject("hex required")
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
