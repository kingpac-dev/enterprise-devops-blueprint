/**
 * Bootstrap.
 *
 * Configuration is fetched BEFORE the application starts, so no component
 * ever observes a half-configured application.
 *
 * The Angular-specific wiring (bootstrapApplication, providers, DI tokens)
 * is deliberately omitted — this example demonstrates the delivery pattern,
 * not the framework. In a real application, `config` below is supplied
 * through an injection token or an APP_INITIALIZER.
 */

import { loadRuntimeConfig, type RuntimeConfig } from './app/runtime-config';

/**
 * Fetch configuration, then start. A failure here stops startup with a
 * message rather than producing an application pointed at nothing — or
 * worse, at the wrong environment.
 */
export async function bootstrap(
  start: (config: RuntimeConfig) => void | Promise<void>,
): Promise<void> {
  let config: RuntimeConfig;

  try {
    config = await loadRuntimeConfig();
  } catch (error) {
    // Fail visibly. A blank page with a console error is a bad outcome; a
    // page that loads and silently talks to the wrong environment is worse.
    reportStartupFailure(error);
    throw error;
  }

  await start(config);
}

function reportStartupFailure(error: unknown): void {
  const message = error instanceof Error ? error.message : String(error);

  // The message names configuration FIELDS, never their values — see
  // validateRuntimeConfig. It is safe to show and safe to log.
  // eslint-disable-next-line no-console
  console.error('[startup] Application could not start:', message);

  const root = document.querySelector('#app-root');
  if (root) {
    root.textContent =
      'The application is not configured correctly and cannot start. ' +
      'Please contact support.';
  }
}
