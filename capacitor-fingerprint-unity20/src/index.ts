import { registerPlugin } from '@capacitor/core';
import type { CapacitorFingerprintPlugin } from './definitions';

export const Fingerprint = registerPlugin<CapacitorFingerprintPlugin>(
  'CapacitorFingerprintPlugin',
);

export * from './definitions';
