#!/bin/bash
# ============================================================================
# switch-traffic.sh — Switches Nginx traffic to the target environment
# ============================================================================
# Usage: ./scripts/switch-traffic.sh <TARGET_ENV> (BLUE or GREEN)
# ============================================================================

TARGET_ENV=$1
if [ -z "$TARGET_ENV" ]; then
    echo "Usage: $0 <TARGET_ENV>"
    echo "Example: $0 GREEN"
    exit 1
fi

TARGET_LOWER=$(echo "$TARGET_ENV" | tr '[:upper:]' '[:lower:]')
CONFIG_FILE="${TARGET_LOWER}.conf"

echo "Switching traffic to $TARGET_ENV..."

# Step 1: Copy the target configuration over active.conf locally
cp docker/nginx/$CONFIG_FILE docker/nginx/active.conf

# Step 2: Validate the new Nginx configuration BEFORE reloading
echo "Validating Nginx configuration..."
if docker compose exec -T nginx nginx -t; then
    echo "✅ Nginx configuration is valid."
else
    echo "❌ Nginx configuration validation failed! Aborting switch."
    # Revert active.conf to whatever was currently active in nginx (this is a simplified revert)
    # The safest approach is leaving it failed locally, as nginx in container wasn't reloaded yet.
    exit 1
fi

# Step 3: Reload Nginx without downtime
echo "Reloading Nginx..."
if docker compose exec -T nginx nginx -s reload; then
    echo "✅ Traffic successfully switched to $TARGET_ENV."
else
    echo "❌ Nginx reload failed!"
    exit 1
fi
