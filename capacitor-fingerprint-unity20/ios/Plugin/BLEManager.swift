import Foundation
import CoreBluetooth

struct BLEConfig {
    let serviceUUID: CBUUID
    let writeCharUUID: CBUUID
    let notifyCharUUID: CBUUID
    let scanDuration: TimeInterval
}

final class BLEManager: NSObject {
    private var central: CBCentralManager!
    private(set) var config: BLEConfig?

    private(set) var discovered: [UUID: CBPeripheral] = [:]
    private var connected: CBPeripheral?
    private var writeChar: CBCharacteristic?
    private var notifyChar: CBCharacteristic?

    var onDevice: ((CBPeripheral, NSNumber?) -> Void)?
    var onConnected: ((CBPeripheral) -> Void)?
    var onDisconnected: ((CBPeripheral, Error?) -> Void)?
    var onData: ((Data) -> Void)?
    var onError: ((String) -> Void)?

    override init() {
        super.init()
        self.central = CBCentralManager(delegate: self, queue: .main)
    }

    func isPoweredOn() -> Bool {
        return central.state == .poweredOn
    }

    func setConfig(serviceUUID: String, writeChar: String, notifyChar: String, scanDurationMs: Int = 8000) {
        self.config = BLEConfig(
            serviceUUID: CBUUID(string: serviceUUID),
            writeCharUUID: CBUUID(string: writeChar),
            notifyCharUUID: CBUUID(string: notifyChar),
            scanDuration: TimeInterval(scanDurationMs) / 1000.0
        )
    }

    func startScan() {
        guard let cfg = config else {
            onError?("BLE config not set")
            return
        }
        discovered.removeAll()
        central.scanForPeripherals(withServices: [cfg.serviceUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
    }

    func stopScan() {
        central.stopScan()
    }

    func connect(id: String, timeout: TimeInterval = 8.0) {
        guard let uuid = UUID(uuidString: id), let p = discovered[uuid] else {
            onError?("Device not found: \(id)")
            return
        }
        central.connect(p, options: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) { [weak self] in
            guard let self = self else { return }
            if self.connected?.identifier != p.identifier {
                self.central.cancelPeripheralConnection(p)
                self.onError?("Connect timeout")
            }
        }
    }

    func disconnect() {
        if let p = connected {
            central.cancelPeripheralConnection(p)
        }
    }

    func send(bytes: [UInt8]) {
        guard let p = connected, let wc = writeChar else {
            onError?("Not connected or write characteristic missing")
            return
        }
        let data = Data(bytes)
        p.writeValue(data, for: wc, type: .withResponse)
    }
}

extension BLEManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn: break
        case .unsupported: onError?("Bluetooth unsupported")
        case .unauthorized: onError?("Bluetooth unauthorized")
        case .poweredOff: onError?("Bluetooth powered off")
        default: break
        }
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {
        discovered[peripheral.identifier] = peripheral
        onDevice?(peripheral, RSSI)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connected = peripheral
        peripheral.delegate = self
        if let cfg = config {
            peripheral.discoverServices([cfg.serviceUUID])
        } else {
            peripheral.discoverServices(nil)
        }
    }

    func centralManager(_ central: CBCentralManager,
                        didFailToConnect peripheral: CBPeripheral,
                        error: Error?) {
        onError?("Failed to connect: \(error?.localizedDescription ?? \"unknown\")")
    }

    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?) {
        if connected?.identifier == peripheral.identifier {
            connected = nil
            writeChar = nil
            notifyChar = nil
        }
        onDisconnected?(peripheral, error)
    }
}

extension BLEManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverServices error: Error?) {
        if let e = error {
            onError?("Discover services error: \(e.localizedDescription)")
            return
        }
        guard let services = peripheral.services, let cfg = config else { return }
        for s in services where s.uuid == cfg.serviceUUID {
            peripheral.discoverCharacteristics([cfg.writeCharUUID, cfg.notifyCharUUID], for: s)
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        if let e = error {
            onError?("Discover characteristics error: \(e.localizedDescription)")
            return
        }
        guard let chars = service.characteristics, let cfg = config else { return }
        for c in chars {
            if c.uuid == cfg.writeCharUUID { writeChar = c }
            if c.uuid == cfg.notifyCharUUID {
                notifyChar = c
                peripheral.setNotifyValue(true, for: c)
            }
        }
        if let conn = connected {
            onConnected?(conn)
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        if let e = error {
            onError?("Notify error: \(e.localizedDescription)")
            return
        }
        guard let data = characteristic.value else { return }
        onData?(data)
    }
}
