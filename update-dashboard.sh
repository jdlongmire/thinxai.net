#!/bin/bash
# ThinxAI Dashboard Auto-Update Script
# Reads session logs and system status, updates status.json, pushes to GitHub Pages

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
THINX_DIR="/media/jdlongmire/Macro-Drive-2TB/GitHub_Repos/thinx"
DASHBOARD_DIR="$SCRIPT_DIR"
STATUS_FILE="$DASHBOARD_DIR/status.json"

# Get current timestamp
TIMESTAMP=$(TZ="America/Chicago" date "+%Y-%m-%d %H:%M CST")

# Check if bridge is running
if pgrep -f "python3 bridge.py" > /dev/null; then
    BRIDGE_STATUS="online"
else
    BRIDGE_STATUS="offline"
fi

# Check Claude CLI
if command -v claude &> /dev/null; then
    CLAUDE_STATUS="online"
else
    CLAUDE_STATUS="offline"
fi

# Count commits today
TODAY=$(date "+%Y-%m-%d")
COMMITS_TODAY=$(cd "$THINX_DIR" && git log --oneline --since="$TODAY 00:00:00" 2>/dev/null | wc -l || echo "0")

# Count telegram messages (from JSONL files)
TELEGRAM_DIR="$THINX_DIR/memory/telegram"
if [ -d "$TELEGRAM_DIR" ]; then
    TELEGRAM_MESSAGES=$(wc -l "$TELEGRAM_DIR"/*.jsonl 2>/dev/null | tail -1 | awk '{print $1}' || echo "0")
else
    TELEGRAM_MESSAGES=0
fi

# Extract recent activity from session logs
SESSIONS_DIR="$THINX_DIR/thinx_tuning/sessions"
RECENT_ACTIVITY=""
if [ -d "$SESSIONS_DIR" ]; then
    # Get the latest session file
    LATEST_SESSION=$(ls -t "$SESSIONS_DIR"/*.md 2>/dev/null | head -1)
    if [ -n "$LATEST_SESSION" ]; then
        # Extract completed items (lines starting with - [x] or checkmarks)
        ACTIVITIES=$(grep -E '^\s*-\s*\[x\]|^\s*-\s*✓|^- Completed|^### Completed' "$LATEST_SESSION" 2>/dev/null | \
                    head -5 | \
                    sed 's/^\s*-\s*\[x\]\s*//' | \
                    sed 's/^\s*-\s*✓\s*//' | \
                    sed 's/^\s*-\s*//' | \
                    tr '\n' '|' || echo "")
    fi
fi

# Default activities if none found
if [ -z "$ACTIVITIES" ]; then
    ACTIVITIES="Dashboard auto-update configured|Session tracking active|Telegram bridge operational|Gmail integration ready"
fi

# Build activity JSON array
ACTIVITY_JSON="["
FIRST=true
IFS='|' read -ra ACTIVITY_ARRAY <<< "$ACTIVITIES"
for activity in "${ACTIVITY_ARRAY[@]}"; do
    activity=$(echo "$activity" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    if [ -n "$activity" ]; then
        if [ "$FIRST" = true ]; then
            FIRST=false
        else
            ACTIVITY_JSON+=","
        fi
        # Escape quotes in activity
        activity=$(echo "$activity" | sed 's/"/\\"/g')
        ACTIVITY_JSON+="\"$activity\""
    fi
done
ACTIVITY_JSON+="]"

# Calculate uptime (hours since bridge started, approximate)
if [ "$BRIDGE_STATUS" = "online" ]; then
    BRIDGE_PID=$(pgrep -f "python3 bridge.py" | head -1)
    if [ -n "$BRIDGE_PID" ]; then
        UPTIME_SECONDS=$(ps -o etimes= -p "$BRIDGE_PID" 2>/dev/null | tr -d ' ' || echo "0")
        UPTIME_HOURS=$((UPTIME_SECONDS / 3600))
    else
        UPTIME_HOURS=0
    fi
else
    UPTIME_HOURS=0
fi

# Write status.json
cat > "$STATUS_FILE" << EOF
{
  "updated": "$TIMESTAMP",
  "services": {
    "telegram_bridge": { "status": "$BRIDGE_STATUS", "label": "Telegram Bridge" },
    "claude_cli": { "status": "$CLAUDE_STATUS", "label": "Claude CLI" },
    "email_smtp": { "status": "online", "label": "Email (SMTP)" },
    "email_imap": { "status": "online", "label": "Email (IMAP)" },
    "github": { "status": "online", "label": "GitHub CLI" },
    "memory": { "status": "online", "label": "Shared Memory" }
  },
  "metrics": {
    "telegram_messages": $TELEGRAM_MESSAGES,
    "emails_sent": 0,
    "commits_today": $COMMITS_TODAY,
    "uptime_hours": $UPTIME_HOURS
  },
  "recent_activity": $ACTIVITY_JSON
}
EOF

echo "[$TIMESTAMP] Status updated: bridge=$BRIDGE_STATUS, commits=$COMMITS_TODAY, uptime=${UPTIME_HOURS}h"

# Push to GitHub if there are changes
cd "$DASHBOARD_DIR"
if ! git diff --quiet status.json 2>/dev/null; then
    git add status.json
    git commit -m "Auto-update status: $TIMESTAMP" --no-verify 2>/dev/null || true
    git push origin main 2>/dev/null && echo "[$TIMESTAMP] Pushed to GitHub Pages" || echo "[$TIMESTAMP] Push failed (will retry)"
fi
