# React with TypeScript and Vite — Reference Implementation

## 1. Overview

This directory provides the minimal, production-grade reference implementation for **React + TypeScript + Vite** frontend single-page applications within the Enterprise DevOps Blueprint.

## 2. Key Architecture Standards Implemented

- **Build Once, Promote Everywhere**: Application artifacts are compiled once into HTML/JS/CSS. Dynamic runtime environment variables (e.g. `API_BASE_URL`, `ENVIRONMENT`) are injected into `window.__RUNTIME_CONFIG__` at container startup via [`runtime-config.sh`](runtime-config.sh).
- **Non-Root Execution**: The runtime container executes as the unprivileged `nginx` user (Port 8080).
- **Healthcheck**: Endpoint `/healthz` responds with HTTP 200 for Docker/Portainer orchestration.
- **Unit Testing**: Unit tests implemented with [Vitest](https://vitest.dev) verifying configuration injection logic.

## 3. Local Development

```bash
npm install
npm run dev
npm run test
```

## 4. Container Build & Run

```bash
docker build -t orders-web:1.0.0 .
docker run -p 8080:8080 -e API_BASE_URL=https://api.orders.devops.local -e ENVIRONMENT=dev orders-web:1.0.0
curl http://localhost:8080/healthz
```
