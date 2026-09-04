import { describe, it, expect, beforeEach, beforeAll } from 'vitest';
import { getRuntimeConfig } from './runtime-config';

describe('RuntimeConfig Loader', () => {
  beforeAll(() => {
    if (typeof window === 'undefined') {
      (globalThis as any).window = globalThis;
    }
  });

  beforeEach(() => {
    delete (window as any).__RUNTIME_CONFIG__;
  });

  it('returns default local configuration when window.__RUNTIME_CONFIG__ is undefined', () => {
    const config = getRuntimeConfig();
    expect(config.environment).toBe('local');
    expect(config.apiBaseUrl).toBe('http://localhost:8080');
    expect(config.enableDiagnostics).toBe(true);
  });

  it('correctly merges runtime configuration injected into window', () => {
    (window as any).__RUNTIME_CONFIG__ = {
      apiBaseUrl: 'https://api.orders.devops.local',
      environment: 'prod',
      enableDiagnostics: false,
      version: '1.4.2-sha-a82f912'
    };

    const config = getRuntimeConfig();
    expect(config.environment).toBe('prod');
    expect(config.apiBaseUrl).toBe('https://api.orders.devops.local');
    expect(config.enableDiagnostics).toBe(false);
    expect(config.version).toBe('1.4.2-sha-a82f912');
  });
});
