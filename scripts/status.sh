#!/bin/bash
# ============================================================================
# status.sh — Displays the current status of the Blue-Green environment
# ============================================================================

echo "============================================================"
echo "Environment Status"
echo "============================================================"

get_service_status() {
    local SERVICE=$1
    local STATUS=$(docker compose ps $SERVICE --format "{{.State}}" 2>/dev/null)
    
    if [ -z "$STATUS" ] || [ "$STATUS" = "exited" ]; then
        echo "stopped"
    else
        echo "$STATUS"
    fi
}

get_health() {
    local SERVICE=$1
    local BODY=$(docker compose exec -T nginx curl -s http://${SERVICE}:8090/api/health 2>/dev/null)
    
    if echo "$BODY" | grep -q '"status":"Healthy"'; then
        echo "healthy"
    else
        echo "unhealthy"
    fi
}

get_version() {
    local SERVICE=$1
    local VERSION=$(docker compose exec -T nginx curl -s http://${SERVICE}:8090/api/health 2>/dev/null | grep -o '"version":"[^"]*"' | cut -d'"' -f4)
    
    if [ -z "$VERSION" ]; then
        echo "N/A"
    else
        echo "$VERSION"
    fi
}

# Blue Status
BLUE_STATUS=$(get_service_status blue-api)
if [ "$BLUE_STATUS" = "running" ]; then
    BLUE_HEALTH=$(get_health blue-api)
    BLUE_VERSION=$(get_version blue-api)
else
    BLUE_HEALTH="N/A"
    BLUE_VERSION="N/A"
fi

# Green Status
GREEN_STATUS=$(get_service_status green-api)
if [ "$GREEN_STATUS" = "running" ]; then
    GREEN_HEALTH=$(get_health green-api)
    GREEN_VERSION=$(get_version green-api)
else
    GREEN_HEALTH="N/A"
    GREEN_VERSION="N/A"
fi

# Active Environment
if [ -f "docker/nginx/active.conf" ]; then
    if grep -q "green-api" docker/nginx/active.conf; then
        ACTIVE_ENV="GREEN"
    else
        ACTIVE_ENV="BLUE"
    fi
else
    ACTIVE_ENV="UNKNOWN (Nginx not configured)"
fi

echo "BLUE:"
echo "  Status: $BLUE_STATUS"
echo "  Health: $BLUE_HEALTH"
echo "  Version: $BLUE_VERSION"
echo ""
echo "GREEN:"
echo "  Status: $GREEN_STATUS"
echo "  Health: $GREEN_HEALTH"
echo "  Version: $GREEN_VERSION"
echo ""
echo "Active Environment:"
echo "  $ACTIVE_ENV"
echo "============================================================"
