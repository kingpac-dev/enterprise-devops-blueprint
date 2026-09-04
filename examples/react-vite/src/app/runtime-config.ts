// ==============================================================================
// Enterprise DevOps Blueprint — React Runtime Configuration Pattern
// Implements: docs/06-container/docker-standard.md
//
// Key Principle: Build once, promote everywhere.
// Environment variables are injected at container startup via runtime-config.sh
// into window.__RUNTIME_CONFIG__, NEVER baked into the production bundle.
// ==============================================================================

export interface RuntimeConfig {
  apiBaseUrl: string;
  environment: 'dev' | 'uat' | 'prod' | 'local';
  enableDiagnostics: boolean;
  version: string;
}

declare global {
  interface Window {
    __RUNTIME_CONFIG__?: Partial<RuntimeConfig>;
  }
}

const DEFAULT_CONFIG: RuntimeConfig = {
  apiBaseUrl: 'http://localhost:8080',
  environment: 'local',
  enableDiagnostics: true,
  version: '1.0.0-local'
};

export function getRuntimeConfig(): RuntimeConfig {
  const windowConfig = typeof window !== 'undefined' ? window.__RUNTIME_CONFIG__ : undefined;

  return {
    apiBaseUrl: windowConfig?.apiBaseUrl || DEFAULT_CONFIG.apiBaseUrl,
    environment: windowConfig?.environment || DEFAULT_CONFIG.environment,
    enableDiagnostics: windowConfig?.enableDiagnostics ?? DEFAULT_CONFIG.enableDiagnostics,
    version: windowConfig?.version || DEFAULT_CONFIG.version
  };
}
