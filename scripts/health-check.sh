export MSYS_NO_PATHCONV=1

TARGET_ENV=$1
if [ -z "$TARGET_ENV" ]; then
    echo "Usage: $0 <TARGET_ENV>"
    echo "Example: $0 GREEN"
    exit 1
fi

TARGET_LOWER=$(echo "$TARGET_ENV" | tr '[:upper:]' '[:lower:]')
SERVICE_NAME="${TARGET_LOWER}-api"

echo "Running health check on $TARGET_ENV environment..."

MAX_RETRIES=10
RETRY_INTERVAL=3
RETRY_COUNT=0
HEALTHY=false

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    echo "Attempt $((RETRY_COUNT + 1))/$MAX_RETRIES..."
    
    BODY=$(docker compose exec -T nginx curl -s http://${SERVICE_NAME}:8090/api/health 2>/dev/null)
    
    if echo "$BODY" | grep -qi "\"environment\":\"$TARGET_ENV\""; then
        echo "✅ $TARGET_ENV is Healthy!"
        echo "Response: $BODY"
        HEALTHY=true
        break
    else
        echo "⚠️ Waiting for $TARGET_ENV to be ready..."
        if [ -n "$BODY" ]; then
            echo "Current Response: $BODY"
        fi
    fi

    RETRY_COUNT=$((RETRY_COUNT + 1))
    sleep $RETRY_INTERVAL
done

if [ "$HEALTHY" = true ]; then
    exit 0
else
    echo "❌ Health check failed after $MAX_RETRIES attempts."
    exit 1
fi

