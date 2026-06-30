# syntax=docker/dockerfile:1

# ---------- Build stage ----------
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Copy only the csproj first so restore is cached unless dependencies change
COPY RateLimiting.Api.csproj ./
RUN dotnet restore "RateLimiting.Api.csproj"

# Copy the rest of the source and publish
COPY . .
RUN dotnet publish "RateLimiting.Api.csproj" \
    -c Release \
    -o /app/publish \
    --no-restore

# ---------- Runtime stage ----------
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final
WORKDIR /app

ENV ASPNETCORE_ENVIRONMENT=Production \
    DOTNET_RUNNING_IN_CONTAINER=true \
    # Don't fail the container if telemetry can't phone home
    DOTNET_CLI_TELEMETRY_OPTOUT=1

# Render (and most PaaS hosts) inject a PORT env var at runtime and expect
# the app to listen on it. Locally it falls back to 8080.
ENV PORT=8080
EXPOSE 8080

COPY --from=build /app/publish .

# The aspnet base image already runs as a non-root "app" user since .NET 8+
ENTRYPOINT ["sh", "-c", "dotnet RateLimiting.Api.dll --urls http://+:${PORT}"]
