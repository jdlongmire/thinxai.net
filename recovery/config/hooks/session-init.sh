#!/bin/bash
# ThinxAI Session Initialization Hook
# Runs on every new Claude Code session to enforce cross-agent awareness

set -e

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-/media/jdlongmire/Macro-Drive-2TB/GitHub_Repos/thinx}"
META_CONTEXT_DIR="$PROJECT_DIR/memory/meta-context/current"
VSCODE_LOG="$META_CONTEXT_DIR/vscode-claude.md"
TELEGRAM_LOG="$META_CONTEXT_DIR/telegram-bridge.md"
MEMORY_FILE="$PROJECT_DIR/MEMORY.md"

# Generate Agent ID
AGENT_ID="Agent_$(date +%Y%m%d_%H%M)"
TIMESTAMP=$(date +%H:%M:%S)
DATE_STR=$(date +%Y-%m-%d)

# Ensure meta-context directory exists
mkdir -p "$META_CONTEXT_DIR"

# Read other agent activity (last 10 lines from Telegram)
TELEGRAM_ACTIVITY=""
if [ -f "$TELEGRAM_LOG" ]; then
    TELEGRAM_ACTIVITY=$(head -50 "$TELEGRAM_LOG" | grep -A3 "^##" | head -20 || echo "No recent activity")
fi

# Log SESSION START to vscode-claude.md
if [ -f "$VSCODE_LOG" ]; then
    # Update header
    sed -i "s/^# Last Update:.*/# Last Update: $TIMESTAMP/" "$VSCODE_LOG"
    sed -i "s/^# Date:.*/# Date: $DATE_STR/" "$VSCODE_LOG"

    # Find the first --- and insert after it
    TEMP_FILE=$(mktemp)
    awk -v entry="
## $TIMESTAMP | $AGENT_ID | thinx repo | SESSION START
**What:** New VS Code Claude session started
**Why:** User initiated claude command
**Context:** Agent ID generated, meta-context loaded

---
" '
    /^---$/ && !done {
        print
        print entry
        done=1
        next
    }
    {print}
    ' "$VSCODE_LOG" > "$TEMP_FILE"
    mv "$TEMP_FILE" "$VSCODE_LOG"
else
    # Create new file
    cat > "$VSCODE_LOG" << EOF
# Activity Pool: vscode-claude
# Date: $DATE_STR
# Last Update: $TIMESTAMP

---

## $TIMESTAMP | $AGENT_ID | thinx repo | SESSION START
**What:** New VS Code Claude session started
**Why:** User initiated claude command
**Context:** Agent ID generated, meta-context loaded

---
EOF
fi

# Build context message for Claude
CONTEXT_MSG="SESSION INITIALIZED - Agent ID: $AGENT_ID

Cross-agent context loaded from Telegram bridge:
$TELEGRAM_ACTIVITY

REQUIRED: Include your Agent ID ($AGENT_ID) in all meta-context entries this session.
Log significant activities to memory/meta-context/current/vscode-claude.md"

# Output for Claude (JSON format for hook output)
cat << EOF
{"hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": "$AGENT_ID initialized. Meta-context loaded. Remember to log activities with your Agent ID."}}
EOF

exit 0
