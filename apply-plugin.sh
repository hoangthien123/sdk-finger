#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./apply-plugin.sh                 # chạy tại root repo hiện tại
#   ./apply-plugin.sh /path/to/repo   # chỉ định đường dẫn repo
#
# Yêu cầu:
# - Git, Node.js (>= 18), npm
# - Có quyền push lên origin
#
# Kết quả:
# - Tạo thư mục capacitor-fingerprint-unity20/ với đầy đủ file plugin
# - Commit & push lên nhánh plugin/pack-tgz
# - Đóng gói .tgz trong capacitor-fingerprint-unity20/

REPO_DIR="${1:-$(pwd)}"
BRANCH="plugin/pack-tgz"
PLUGIN_DIR="capacitor-fingerprint-unity20"
PKG_TGZ=""

echo "==> Repo dir: ${REPO_DIR}"
if [ ! -d "${REPO_DIR}/.git" ]; then
  echo "ERROR: ${REPO_DIR} không phải root của một Git repo."
  exit 1
fi

command -v git >/dev/null 2>&1 || { echo "ERROR: git not found"; exit 1; }
command -v node >/dev/null 2>&1 || { echo "ERROR: node not found (yêu cầu Node >= 18)"; exit 1; }
command -v npm  >/dev/null 2>&1 || { echo "ERROR: npm not found"; exit 1; }

cd "${REPO_DIR}"

echo "==> Fetch origin..."
git fetch origin --prune

# Tìm default branch
DEFAULT_BRANCH="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | awk -F/ '{print $2}')"
if [ -z "${DEFAULT_BRANCH}" ]; then
  DEFAULT_BRANCH="main"
fi

# Checkout nhánh mục tiêu
if git rev-parse --verify "${BRANCH}" >/dev/null 2>&1; then
  echo "==> Checkout local branch ${BRANCH}..."
  git checkout "${BRANCH}"
else
  if git ls-remote --exit-code --heads origin "${BRANCH}" >/dev/null 2>&1; then
    echo "==> Checkout remote branch ${BRANCH}..."
    git checkout -t "origin/${BRANCH}"
  else
    echo "==> Create branch ${BRANCH} from ${DEFAULT_BRANCH}..."
    git checkout "${DEFAULT_BRANCH}"
    git checkout -b "${BRANCH}"
  fi
fi

echo "==> Creating plugin structure: ${PLUGIN_DIR} ..."
mkdir -p "${PLUGIN_DIR}/src" "${PLUGIN_DIR}/ios/Plugin"

# package.json
cat > "${PLUGIN_DIR}/package.json" <<'EOF'
{
  "name": "@hoangthien123/capacitor-fingerprint-unity20",
  "version": "0.1.0",
  "description": "Capacitor v7 plugin for Unity20 BLE fingerprint (iOS)",
  "main": "dist/index.js",
  "types": "dist/definitions.d.ts",
  "files": [
    "dist/",
    "ios/",
    "USAGE.md",
    "README.md",
    "Hoangthien123CapacitorFingerprintUnity20.podspec"
  ],
  "scripts": {
    "build": "tsc -p tsconfig.json && cp README.md dist/ || true",
    "prepack": "npm run build"
  },
  "author": "hoangthien123",
  "license": "MIT",
  "devDependencies": {
    "typescript": "^5.6.3",
    "@capacitor/core": "^7.0.0"
  },
  "peerDependencies": {
    "@capacitor/core": "^7.0.0"
  },
  "engines": {
    "node": ">=18"
  },
  "capacitor": {
    "ios": {
      "src": "ios"
    }
  }
}
EOF

# tsconfig.json
cat > "${PLUGIN_DIR}/tsconfig.json" <<'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "ES2020",
    "lib": ["ES2020", "DOM"],
    "declaration": true,
    "outDir": "dist",
    "strict": true,
    "moduleResolution": "node",
    "esModuleInterop": true,
    "skipLibCheck": true
  },
  "include": ["src"]
}
EOF

# src/definitions.ts
cat > "${PLUGIN_DIR}/src/definitions.ts" <<'EOF'
import type { PluginListenerHandle } from '@capacitor/core';

export interface InitializeOptions {
  serviceUUID: string;
  writeCharacteristicUUID: string;
  notifyCharacteristicUUID: string;
  scanDurationMs?: number;
  mtu?: number;
}

export interface DeviceInfo {
  id: string;
  name?: string;
  rssi?: number;
}

export interface ConnectOptions {
  deviceId: string;
  timeoutMs?: number;
}

export interface SendCommandOptions {
  hex: string;
  frame?: boolean;
}

export interface ReceivedData {
  hex: string;
  bytes: number[];
}

export interface CapacitorFingerprintPlugin {
  initialize(options: InitializeOptions): Promise<void>;
  scan(): Promise<{ devices: DeviceInfo[] }>;
  stopScan(): Promise<void>;
  connect(options: ConnectOptions): Promise<void>;
  disconnect(): Promise<void>;
  sendCommand(options: SendCommandOptions): Promise<{ ok: boolean }>;

  addListener(
    eventName: 'deviceDiscovered',
    listenerFunc: (device: DeviceInfo) => void
  ): Promise<PluginListenerHandle>;

  addListener(
    eventName: 'connected' | 'disconnected',
    listenerFunc: (data: { deviceId: string }) => void
  ): Promise<PluginListenerHandle>;

  addListener(
    eventName: 'data',
    listenerFunc: (data: ReceivedData) => void
  ): Promise<PluginListenerHandle>;

  addListener(
    eventName: 'error',
    listenerFunc: (data: { message: string }) => void
  ): Promise<PluginListenerHandle>;
}
EOF

# src/index.ts
cat > "${PLUGIN_DIR}/src/index.ts" <<'EOF'
import { registerPlugin } from '@capacitor/core';
import type { CapacitorFingerprintPlugin } from './definitions';

export const Fingerprint = registerPlugin<CapacitorFingerprintPlugin>(
  'CapacitorFingerprintPlugin',
);

export * from './definitions';
EOF

# iOS Swift files
cat > "${PLUGIN_DIR}/ios/Plugin/CommandCodec.swift" <<'EOF'
import Foundation

enum Hex {
    static func toBytes(_ hex: String) -> [UInt8] {
        let cleaned = hex.replacingOccurrences(of: " ", with: "").lowercased()
        var bytes = [UInt8]()
        var index = cleaned.startIndex
        while index < cleaned.endIndex {
            let nextIndex = cleaned.index(index, offsetBy: 2, limitedBy: cleaned.endIndex) ?? cleaned.endIndex
            if nextIndex <= index { break }
            let byteString = String(cleaned[index..<nextIndex])
            if let b = UInt8(byteString, radix: 16) {
                bytes.append(b)
            }
            index = nextIndex
        }
        return bytes
    }

    static func fromBytes(_ bytes: [UInt8]) -> String {
        return bytes.map { String(format: "%02X", $0) }.joined()
    }
}

// Placeholder cho framing FMS nếu cần (header/length/CRC)
struct CommandCodec {
    static func frame(_ payload: [UInt8]) -> [UInt8] {
        return payload
    }
}
EOF

cat > "${PLUGIN_DIR}/ios/Plugin/BLEManager.swift" <<'EOF'
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
EOF

cat > "${PLUGIN_DIR}/ios/Plugin/Plugin.swift" <<'EOF'
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
EOF

# Podspec (đúng tên CococaPods mà Capacitor sinh ra)
cat > "${PLUGIN_DIR}/Hoangthien123CapacitorFingerprintUnity20.podspec" <<'EOF'
Pod::Spec.new do |s|
  s.name             = 'Hoangthien123CapacitorFingerprintUnity20'
  s.version          = '0.1.0'
  s.summary          = 'Capacitor v7 plugin for Unity20 BLE fingerprint (iOS)'
  s.license          = { :type => 'MIT' }
  s.homepage         = 'https://github.com/hoangthien123/sdk-finger'
  s.author           = { 'hoangthien123' => 'noreply@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'ios/Plugin/**/*.{swift,h,m,mm,c}'
  s.ios.deployment_target = '13.0'
  s.swift_version    = '5.0'
  s.static_framework = true
  s.dependency       'Capacitor'
end
EOF

# README.md (ngắn gọn để tránh lỗi quoting)
cat > "${PLUGIN_DIR}/README.md" <<'EOF'
@hoangthien123/capacitor-fingerprint-unity20 (Capacitor v7)
Plugin iOS BLE cho Unity20 Fingerprint.
Pod name: Hoangthien123CapacitorFingerprintUnity20

Cài (.tgz):
npm i ./hoangthien123-capacitor-fingerprint-unity20-0.1.0.tgz
npx cap sync ios
EOF

# USAGE.md
cat > "${PLUGIN_DIR}/USAGE.md" <<'EOF'
Tạo .tgz:
npm install
npm pack

Cài vào app (Capacitor v7):
npm i ./hoangthien123-capacitor-fingerprint-unity20-0.1.0.tgz
npx cap sync ios

Thêm vào Info.plist:
- NSBluetoothAlwaysUsageDescription
- NSBluetoothPeripheralUsageDescription
EOF

echo "==> Git add/commit/push..."
git add "${PLUGIN_DIR}"
if ! git diff --cached --quiet; then
  git commit -m "Add Capacitor v7 Unity20 BLE fingerprint plugin (apply script)"
  git push origin "${BRANCH}"
else
  echo "No changes to commit."
fi

echo "==> Building & packing .tgz..."
pushd "${PLUGIN_DIR}" >/dev/null
npm install --silent
PKG_TGZ="$(npm pack --silent)"
popd >/dev/null

ABS_TGZ="$(cd "${PLUGIN_DIR}"; pwd)/${PKG_TGZ}"
echo "==> Done."
echo "TGZ file: ${ABS_TGZ}"
echo "Install in your Ionic app:"
echo "npm i \"${ABS_TGZ}\" && npx cap sync ios"