#!/bin/bash
set -e

QUERIES_DIR="/app/queries"
OUTPUT_DIR="/app/output"
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)

log() {
    echo "[$(date +'%H:%M:%S')] $*"
}

log "Installing Steampipe AWS plugin..."
steampipe plugin install aws 2>/dev/null || true

mkdir -p "$OUTPUT_DIR"

QUERY_FILES=$(find "$QUERIES_DIR" -name "*.sql" -type f 2>/dev/null)

if [ -z "$QUERY_FILES" ]; then
    log "No query files found"
    exit 0
fi

QUERY_COUNT=$(echo "$QUERY_FILES" | wc -l | tr -d ' ')
log "Found $QUERY_COUNT query file(s)"

SUCCESS_COUNT=0
NOTIFICATION_COUNT=0

for QUERY_FILE in $QUERY_FILES; do
    QUERY_NAME=$(basename "$QUERY_FILE" .sql)
    OUTPUT_FILE="$OUTPUT_DIR/${QUERY_NAME}_${TIMESTAMP}.json"
    
    log "Running: $QUERY_NAME"
    
    if ! steampipe query "$QUERY_FILE" --output json > "$OUTPUT_FILE" 2>&1; then
        log "ERROR: Query failed - $QUERY_NAME"
        rm -f "$OUTPUT_FILE"
        continue
    fi
    
    ROW_COUNT=$(jq -r '.rows | length' "$OUTPUT_FILE" 2>/dev/null || echo "0")
    
    if [ "$ROW_COUNT" = "0" ] || [ ! -s "$OUTPUT_FILE" ]; then
        log "No results for: $QUERY_NAME"
        rm -f "$OUTPUT_FILE"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        continue
    fi
    
    log "Found $ROW_COUNT item(s) in $QUERY_NAME"
    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    
    if [ -n "$SNS_TOPIC_ARN" ]; then
        DISPLAY_NAME=$(echo "$QUERY_NAME" | tr '_' ' ' | sed 's/\b\(.\)/\u\1/g')
        FINDINGS=$(jq -r '.rows[0:5] | map(. | to_entries | map("\(.key): \(.value)") | join(", ")) | map("  - " + .) | join("\n")' "$OUTPUT_FILE")
        
        if [ "$ROW_COUNT" -gt 5 ]; then
            FINDINGS="$FINDINGS\n  ...and $((ROW_COUNT - 5)) more items"
        fi
        
        MESSAGE=$(cat <<EOF
{
  "version": "1.0",
  "source": "custom",
  "content": {
    "textType": "client-markdown",
    "title": "AWS Report: $DISPLAY_NAME",
    "description": "**Found:** $ROW_COUNT item(s)\n**Query:** $QUERY_NAME\n\n**Details:**\n$FINDINGS"
  }
}
EOF
)
        
        log "Sending notification for: $QUERY_NAME"
        if aws sns publish \
            --topic-arn "$SNS_TOPIC_ARN" \
            --message "$MESSAGE" \
            --region "${AWS_REGION:-us-east-1}" \
            >/dev/null 2>&1; then
            NOTIFICATION_COUNT=$((NOTIFICATION_COUNT + 1))
        else
            log "WARNING: Failed to send notification"
        fi
    fi
done

log "Complete: $SUCCESS_COUNT/$QUERY_COUNT queries successful"
log "Sent $NOTIFICATION_COUNT notifications"
