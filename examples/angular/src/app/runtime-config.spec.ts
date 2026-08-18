/**
 * Tests for the runtime configuration loader.
 *
 * Written against a minimal assertion helper rather than a test framework, so
 * the file type-checks and runs without pulling in a runner. In a real
 * project these would be Jasmine or Vitest specs.
 *
 * They cover the FAILURE paths deliberately — each represents a
 * misconfiguration that would otherwise start successfully and misbehave.
 */

import { validateRuntimeConfig, type RuntimeConfig } from './runtime-config';

type TestCase = { readonly name: string; readonly run: () => void };

function assert(condition: boolean, message: string): void {
  if (!condition) {
    throw new Error(`Assertion failed: ${message}`);
  }
}

function expectThrows(fn: () => unknown, expectedSubstring: string): void {
  try {
    fn();
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    assert(
      message.includes(expectedSubstring),
      `expected message to contain "${expectedSubstring}", got "${message}"`,
    );
    return;
  }
  throw new Error(`Expected a throw containing "${expectedSubstring}", but nothing was thrown.`);
}

const valid = {
  apiBaseUrl: 'https://api.example.internal',
  environment: 'prod',
  logLevel: 'warn',
  featureFlags: { newCheckout: true },
};

export const tests: readonly TestCase[] = [
  {
    name: 'accepts a valid configuration',
    run: () => {
      const config: RuntimeConfig = validateRuntimeConfig(valid);
      assert(config.apiBaseUrl === 'https://api.example.internal', 'apiBaseUrl preserved');
      assert(config.environment === 'prod', 'environment preserved');
      assert(config.featureFlags['newCheckout'] === true, 'flag preserved');
    },
  },
  {
    name: 'rejects a missing apiBaseUrl',
    run: () => expectThrows(() => validateRuntimeConfig({ ...valid, apiBaseUrl: '' }), 'apiBaseUrl'),
  },
  {
    name: 'rejects an unknown environment',
    run: () =>
      expectThrows(() => validateRuntimeConfig({ ...valid, environment: 'staging' }), 'environment'),
  },
  {
    name: 'rejects a non-object payload',
    run: () => expectThrows(() => validateRuntimeConfig('not json'), 'not an object'),
  },
  {
    name: 'rejects a non-boolean feature flag',
    run: () =>
      expectThrows(
        () => validateRuntimeConfig({ ...valid, featureFlags: { newCheckout: 'yes' } }),
        'featureFlags.newCheckout',
      ),
  },
  {
    name: 'defaults logLevel safely rather than failing',
    run: () => {
      // logLevel is optional with a safe default; apiBaseUrl and environment
      // are not. The distinction is deliberate: a wrong log level is a
      // nuisance, a wrong API base URL points at another environment.
      const config = validateRuntimeConfig({ ...valid, logLevel: 'nonsense' });
      assert(config.logLevel === 'warn', 'logLevel falls back to warn');
    },
  },
  {
    name: 'error message contains no configuration values',
    run: () => {
      // The message can reach a browser console and an error report.
      try {
        validateRuntimeConfig({ ...valid, apiBaseUrl: '', environment: 'nope' });
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        assert(!message.includes('nope'), 'the invalid VALUE must not appear in the message');
        return;
      }
      throw new Error('Expected a throw.');
    },
  },
];

export function runTests(): void {
  let passed = 0;
  for (const test of tests) {
    test.run();
    passed += 1;
  }
  // eslint-disable-next-line no-console
  console.log(`runtime-config: ${passed}/${tests.length} passed`);
}
