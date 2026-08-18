# syntax=docker/dockerfile:1
#
# Adapted from templates/docker/Dockerfile.dotnet-worker for this example.
#
# NOT BUILT. No Docker daemon was available in the authoring environment, so
# this file has never been through `docker build`. Build it once before
# relying on it.

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

COPY ["src/Orders.Worker/Orders.Worker.csproj", "src/Orders.Worker/"]
RUN dotnet restore "src/Orders.Worker/Orders.Worker.csproj"

COPY . .
RUN dotnet publish "src/Orders.Worker/Orders.Worker.csproj" \
        --configuration Release --no-restore --output /app/publish

# The .NET runtime image, NOT aspnet. This worker has no HTTP surface, so the
# ASP.NET stack would be attack surface for nothing.
FROM mcr.microsoft.com/dotnet/runtime:8.0 AS final

ARG VERSION=0.0.0
ARG GIT_COMMIT=unknown
ARG BUILD_TIMESTAMP=unknown

LABEL org.opencontainers.image.title="orders-worker" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${GIT_COMMIT}" \
      org.opencontainers.image.created="${BUILD_TIMESTAMP}" \
      org.opencontainers.image.vendor="TBD"

RUN groupadd --system --gid 1001 appgroup \
 && useradd  --system --uid 1001 --gid appgroup --no-create-home appuser \
 && mkdir -p /var/run/worker \
 && chown 1001:1001 /var/run/worker

WORKDIR /app
COPY --from=build --chown=1001:1001 /app/publish .

USER 1001

ENV DOTNET_RUNNING_IN_CONTAINER=true \
    Worker__LivenessFile=/var/run/worker/alive \
    Worker__ShutdownTimeout=00:00:30 \
    WORKER_LIVENESS_MAX_AGE_SECONDS=120

# Written with `test` rather than `[ ... ]`: a CMD argument beginning with
# `[` is parsed as JSON exec form first.
#
# Fails when the liveness file goes stale — a worker that is running and no
# longer processing, which process liveness alone would not detect.
HEALTHCHECK --interval=60s --timeout=5s --start-period=30s --retries=2 \
    CMD test -f "$Worker__LivenessFile" \
        && test $(( $(date +%s) - $(stat -c %Y "$Worker__LivenessFile") )) -lt "$WORKER_LIVENESS_MAX_AGE_SECONDS" \
        || exit 1

# No EXPOSE. No HTTP surface.
#
# Exec form, so SIGTERM reaches the application and the host's shutdown
# sequence runs. The container stop_grace_period must exceed
# Worker__ShutdownTimeout — see templates/compose/compose.prod.yml
ENTRYPOINT ["dotnet", "Orders.Worker.dll"]
