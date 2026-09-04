# Go API with Fiber — Reference Implementation

## 1. Overview

This directory provides the minimal, production-grade reference implementation for high-throughput **Go REST APIs** using the **Fiber** framework within the Enterprise DevOps Blueprint.

## 2. Key Architecture Standards Implemented

- **Static Binary Multi-Stage Build**: Compiles a static Linux binary (`CGO_ENABLED=0`) with symbol stripping (`-ldflags="-s -w"`) inside a temporary builder stage.
- **Minimal Unprivileged Runtime**: Deploys into an unprivileged Alpine container running as `appuser` (`UID 10001:GID 10001`).
- **Health Probes**: Implements separate endpoints for:
  - Liveness: `/healthz` (Process running)
  - Readiness: `/readyz` (Dependencies verified)
- **Metrics**: Exposes Prometheus-compatible metrics endpoint at `/metrics`.
- **Graceful Shutdown**: Intercepts `SIGINT` and `SIGTERM` signals for clean drain of active HTTP connections.

## 3. Local Development

```bash
go test -v ./...
go run main.go
```

Test endpoints:
```bash
curl http://localhost:8080/healthz
curl http://localhost:8080/readyz
curl http://localhost:8080/api/v1/orders
```

## 4. Container Build & Run

```bash
docker build -t orders-api-go:1.0.0 .
docker run -p 8080:8080 orders-api-go:1.0.0
```
