Tạo .tgz:
npm install
npm pack

Cài vào app (Capacitor v7):
npm i ./hoangthien123-capacitor-fingerprint-unity20-0.1.0.tgz
npx cap sync ios

Thêm vào Info.plist:
- NSBluetoothAlwaysUsageDescription
- NSBluetoothPeripheralUsageDescription
