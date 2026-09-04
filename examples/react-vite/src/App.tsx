import { getRuntimeConfig } from './app/runtime-config';

export function App(): JSX.Element {
  const config = getRuntimeConfig();

  return (
    <div style={{ fontFamily: 'sans-serif', padding: '2rem', maxWidth: '800px', margin: '0 auto' }}>
      <h1>Enterprise DevOps Blueprint — React + Vite Reference</h1>
      <p>This reference application demonstrates production-ready runtime environment configuration injection.</p>
      
      <div style={{ background: '#f5f5f5', padding: '1.5rem', borderRadius: '8px', marginTop: '1rem' }}>
        <h3>Current Runtime Configuration</h3>
        <ul>
          <li><strong>Environment:</strong> <code>{config.environment}</code></li>
          <li><strong>API Base URL:</strong> <code>{config.apiBaseUrl}</code></li>
          <li><strong>Version:</strong> <code>{config.version}</code></li>
          <li><strong>Diagnostics:</strong> <code>{config.enableDiagnostics ? 'Enabled' : 'Disabled'}</code></li>
        </ul>
      </div>
    </div>
  );
}
