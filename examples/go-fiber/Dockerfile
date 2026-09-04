# ==============================================================================
# Enterprise DevOps Blueprint — Go Fiber Multi-Stage Dockerfile
# Implements: docs/06-container/dockerfile-standard.md
# ==============================================================================

# Stage 1: Build
FROM golang:1.22-alpine AS build

WORKDIR /src

# Install build dependencies
RUN apk add --no-cache git ca-certificates

# Copy dependency files first for layer caching
COPY go.mod go.sum ./
RUN go mod download

# Copy application source
COPY . .

# Compile static binary without CGO
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -trimpath -ldflags="-s -w" -o /bin/orders-api .

# Stage 2: Runtime
FROM alpine:3.19 AS runtime

# Install ca-certificates and curl/wget for healthcheck
RUN apk add --no-cache ca-certificates wget tzdata && \
    addgroup -g 10001 appgroup && \
    adduser -u 10001 -G appgroup -D -s /bin/sh appuser

WORKDIR /app

# Copy binary from build stage
COPY --from=build /bin/orders-api /app/orders-api

# Execute as unprivileged non-root user
USER appuser:appgroup

EXPOSE 8080

HEALTHCHECK --interval=20s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://127.0.0.1:8080/healthz || exit 1

ENTRYPOINT ["/app/orders-api"]
