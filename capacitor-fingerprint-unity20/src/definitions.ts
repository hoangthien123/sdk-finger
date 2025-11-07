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
