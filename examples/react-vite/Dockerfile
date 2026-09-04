# ==============================================================================
# Enterprise DevOps Blueprint — React Vite Multi-Stage Dockerfile
# Implements: docs/06-container/dockerfile-standard.md
# ==============================================================================

# Stage 1: Build
FROM node:20-alpine AS build

WORKDIR /app

# Copy dependency manifests first for build caching
COPY package.json ./

# Install dependencies (frozen lockfile in CI)
RUN npm install

COPY . .

# Build production bundle and run test suite
RUN npm run test && npm run build

# Stage 2: Runtime
FROM nginx:1.25-alpine AS runtime

# Copy custom non-root Nginx config
COPY nginx.conf /etc/nginx/nginx.conf

# Copy build artifacts
COPY --from=build /app/dist /usr/share/nginx/html

# Copy runtime config bootstrap script
COPY runtime-config.sh /docker-entrypoint.d/40-runtime-config.sh
RUN chmod +x /docker-entrypoint.d/40-runtime-config.sh

# Configure non-root permissions for Nginx
RUN chown -R nginx:nginx /usr/share/nginx/html /var/cache/nginx /var/log/nginx /var/run && \
    touch /var/run/nginx.pid && \
    chown -R nginx:nginx /var/run/nginx.pid

USER nginx

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://127.0.0.1:8080/healthz || exit 1

CMD ["nginx", "-g", "daemon off;"]
