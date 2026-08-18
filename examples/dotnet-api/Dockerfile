# syntax=docker/dockerfile:1
#
# Adapted from templates/docker/Dockerfile.dotnet-api for this example.
#
# NOT BUILT. No Docker daemon was available in the authoring environment.

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

COPY ["src/Orders.Api/Orders.Api.csproj", "src/Orders.Api/"]
RUN dotnet restore "src/Orders.Api/Orders.Api.csproj"

COPY . .
RUN dotnet publish "src/Orders.Api/Orders.Api.csproj" \
        --configuration Release --no-restore --output /app/publish

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final

ARG VERSION=0.0.0
ARG GIT_COMMIT=unknown
ARG BUILD_TIMESTAMP=unknown

LABEL org.opencontainers.image.title="orders-api" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${GIT_COMMIT}" \
      org.opencontainers.image.created="${BUILD_TIMESTAMP}" \
      org.opencontainers.image.vendor="TBD"

# curl is installed solely so the container can health-check itself.
# A documented exception to "no unnecessary tools in the runtime stage" —
# see templates/docker/README.md for the alternatives.
RUN apt-get update \
 && apt-get install --yes --no-install-recommends curl \
 && rm -rf /var/lib/apt/lists/*

RUN groupadd --system --gid 1001 appgroup \
 && useradd  --system --uid 1001 --gid appgroup --no-create-home appuser

WORKDIR /app
COPY --from=build --chown=1001:1001 /app/publish .

USER 1001

# Above 1024, because a non-root process cannot bind lower.
ENV ASPNETCORE_HTTP_PORTS=8080 \
    ASPNETCORE_ENVIRONMENT=Production \
    DOTNET_RUNNING_IN_CONTAINER=true
EXPOSE 8080

# LIVENESS, not readiness.
#
# The container health check asks "should this process keep running?".
# Readiness is polled by the DEPLOYMENT, which asks a different question:
# "can it serve traffic yet?". Using readiness here would restart the
# container whenever a dependency is slow — repeatedly, fixing nothing.
HEALTHCHECK --interval=30s --timeout=3s --start-period=20s --retries=3 \
    CMD curl --fail --silent --show-error http://127.0.0.1:8080/health/live || exit 1

ENTRYPOINT ["dotnet", "Orders.Api.dll"]
