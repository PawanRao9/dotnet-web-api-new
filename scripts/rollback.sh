#!/bin/bash
# ============================================================================
# rollback.sh — Reverts traffic to the previous environment
# ============================================================================

echo "============================================================"
echo "Starting Rollback Procedure"
echo "============================================================"

# Determine current active environment from active.conf
if grep -q "green-api" docker/nginx/active.conf; then
    CURRENT_ENV="GREEN"
    PREVIOUS_ENV="BLUE"
else
    CURRENT_ENV="BLUE"
    PREVIOUS_ENV="GREEN"
fi

echo "Current active environment : $CURRENT_ENV"
echo "Rolling back to            : $PREVIOUS_ENV"
echo "------------------------------------------------------------"

# Verify the previous environment is healthy before rolling back
if bash ./scripts/health-check.sh $PREVIOUS_ENV; then
    echo "------------------------------------------------------------"
    echo "$PREVIOUS_ENV is healthy. Proceeding with rollback switch."
    
    if bash ./scripts/switch-traffic.sh $PREVIOUS_ENV; then
        echo "============================================================"
        echo "⏪ ROLLBACK SUCCESSFUL!"
        echo "Active Environment: $PREVIOUS_ENV"
        echo "============================================================"
        exit 0
    else
        echo "============================================================"
        echo "❌ ROLLBACK SWITCH FAILED."
        echo "Active Environment remains: $CURRENT_ENV"
        echo "============================================================"
        exit 1
    fi
else
    echo "------------------------------------------------------------"
    echo "❌ ROLLBACK FAILED: Previous environment ($PREVIOUS_ENV) is unhealthy or unavailable."
    echo "Cannot safely rollback. Active Environment remains: $CURRENT_ENV"
    echo "============================================================"
    exit 1
fi
