#!/bin/bash
# ============================================================================
# deploy.sh — Orchestrates the Blue-Green Deployment
# ============================================================================
# Usage: ./scripts/deploy.sh [NEW_VERSION]
# ============================================================================

NEW_VERSION=${1:-"latest"}

echo "============================================================"
echo "Starting Blue-Green Deployment (Version: $NEW_VERSION)"
echo "============================================================"

# Ensure Nginx is running to determine active environment
if ! docker compose ps | grep -q nginx; then
    echo "Nginx is not running. Starting initial stack..."
    docker compose up -d
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

# In a real environment, we might pull a new image or set the new version in .env
# For this demo, we'll update the APP_VERSION for the target service dynamically if supported,
# but Docker Compose environment variables are usually read from the host .env or docker-compose.yml.
# Here, we assume the image 'blue-green-api:latest' is already built with the new code.

echo "Starting $TARGET_ENV container..."
docker compose up -d --no-deps --build $TARGET_SERVICE

# Wait for startup
echo "Waiting for container startup..."
sleep 5

# Run Health Check
echo "------------------------------------------------------------"
if bash ./scripts/health-check.sh $TARGET_ENV; then
    echo "------------------------------------------------------------"
    echo "$TARGET_ENV health check passed. Proceeding with traffic switch."
    
    if bash ./scripts/switch-traffic.sh $TARGET_ENV; then
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
