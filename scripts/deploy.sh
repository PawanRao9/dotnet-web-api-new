#!/bin/bash
set -euo pipefail

NEW_VERSION=${1:-"latest"}

echo "============================================================"
echo "Starting Blue-Green Deployment (Version: $NEW_VERSION)"
echo "============================================================"

# Detect Docker Compose command (V2: docker compose, V1: docker-compose)
COMPOSE_CMD=""
if docker compose version &>/dev/null; then
    COMPOSE_CMD="docker compose"
elif command -v docker-compose &>/dev/null; then
    COMPOSE_CMD="docker-compose"
else
    echo "❌ Docker Compose is not installed."
    exit 1
fi

echo "Using Docker Compose command: $COMPOSE_CMD"

# Ensure Nginx is running to determine active environment
if ! $COMPOSE_CMD ps | grep -q nginx; then
    echo "Nginx is not running. Starting initial stack..."
    $COMPOSE_CMD up -d
    sleep 5
fi

# Determine current active environment from active.conf
if grep -q "green-api" docker/nginx/active.conf; then
    CURRENT_ENV="GREEN"
    TARGET_ENV="BLUE"
    TARGET_SERVICE="blue-api"
else
    CURRENT_ENV="BLUE"
    TARGET_ENV="GREEN"
    TARGET_SERVICE="green-api"
fi

echo "Current environment: $CURRENT_ENV"
echo "Target environment : $TARGET_ENV"
echo "Deploying version  : $NEW_VERSION"
echo "------------------------------------------------------------"

echo "Starting $TARGET_ENV container..."
$COMPOSE_CMD up -d --no-deps --build "$TARGET_SERVICE"

# Wait for startup
echo "Waiting for container startup..."
sleep 5

# Run Health Check
echo "------------------------------------------------------------"
if bash ./scripts/health-check.sh "$TARGET_ENV"; then
    echo "------------------------------------------------------------"
    echo "$TARGET_ENV health check passed. Proceeding with traffic switch."
    
    if bash ./scripts/switch-traffic.sh "$TARGET_ENV"; then
        echo "============================================================"
        echo "🎉 DEPLOYMENT SUCCESSFUL!"
        echo "Active Environment: $TARGET_ENV"
        echo "============================================================"
        exit 0
    else
        echo "============================================================"
        echo "❌ TRAFFIC SWITCH FAILED. Deployment aborted."
        echo "Active Environment remains: $CURRENT_ENV"
        echo "============================================================"
        exit 1
    fi
else
    echo "------------------------------------------------------------"
    echo "❌ HEALTH CHECK FAILED. Deployment aborted."
    echo "Traffic was NOT switched. Active Environment remains: $CURRENT_ENV"
    echo "============================================================"
    exit 1
fi
