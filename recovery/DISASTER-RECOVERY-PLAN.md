# ThinxAI Disaster Recovery Plan

**Version:** 1.1
**Last Updated:** 2026-02-03
**Recovery Time Objective (RTO):** 30 minutes
**Recovery Point Objective (RPO):** 24 hours (daily backups)

> **See also:** [CURRENT-ARCHITECTURE.md](CURRENT-ARCHITECTURE.md) for live system configuration snapshot.

---

## Table of Contents

1. [System Overview](#1-system-overview)
2. [Disaster Scenarios](#2-disaster-scenarios)
3. [Pre-Disaster Preparation](#3-pre-disaster-preparation)
4. [Recovery Procedures](#4-recovery-procedures)
5. [Validation Checklist](#5-validation-checklist)
6. [Maintenance Schedule](#6-maintenance-schedule)

---

## 1. System Overview

### Components

| Component | Technology | Location | Port | Critical? |
|-----------|------------|----------|------|-----------|
| Telegram Bridge | Python 3.10+ | `thinxai-telegram/bridge.py` | 18789 | Yes |
| Web Chat | Python 3.10+ | `thinxai-web/web_chat.py` | 8088 | Yes |
| Memory System | Markdown/JSONL | `memory/`, `MEMORY.md` | - | Yes |
| Meta-Context Pool | Markdown | `memory/meta-context/` | - | Medium |
| Automation Scripts | Bash | `scripts/` | - | Medium |
| Dashboard | GitHub Pages | thinxai.net repo | - | No |

### Hardware (Current Workstation)

| Component | Spec |
|-----------|------|
| Machine | Dell OptiPlex 3050 |
| OS | Ubuntu 22.04.5 LTS |
| CPU | Intel i5-7500 (4 cores @ 3.4GHz) |
| RAM | 16 GB |
| Storage | 238 GB SSD (system) + 1.8 TB HDD (data) |

### External Dependencies

| Service | Purpose | Credential Type |
|---------|---------|-----------------|
| Telegram Bot API | Message routing | Bot token |
| Gmail SMTP/IMAP | Email integration | App password |
| Claude Code CLI | AI processing | Local auth |
| GitHub | Repository storage | gh CLI auth |

### Service Definitions

- **Telegram Bridge:** `bridge.py` (port 18789, localhost + Tailscale)
- **Web Chat:** `web_chat.py` (port 8088, all interfaces)
- **Cron Jobs:** User crontab (jdlongmire) - 5 jobs total
- **Email:** msmtp via ThinxAI.jdl@gmail.com

---

## 2. Disaster Scenarios

### Scenario A: Process Crash
**Impact:** Bridge offline, messages not processed
**Recovery Time:** 10 seconds (auto) or 1 minute (manual)
**Procedure:** Systemd auto-restart handles this. If manual: `systemctl restart thinxai-telegram`

### Scenario B: Credential Loss
**Impact:** Cannot authenticate to Telegram/Gmail
**Recovery Time:** 15 minutes
**Procedure:** See [4.2 Credential Recovery](#42-credential-recovery)

### Scenario C: Machine Failure (HDD/SSD)
**Impact:** Complete data loss on local machine
**Recovery Time:** 30 minutes
**Procedure:** See [4.3 Full System Recovery](#43-full-system-recovery)

### Scenario D: Repository Corruption
**Impact:** Git history corrupted or files missing
**Recovery Time:** 10 minutes
**Procedure:** Clone fresh from GitHub, restore local-only files

### Scenario E: Account Compromise
**Impact:** Unauthorized access to bot or email
**Recovery Time:** 5 minutes
**Procedure:** Immediate credential rotation (see [4.4 Security Incident](#44-security-incident))

---

## 3. Pre-Disaster Preparation

### 3.1 Credential Backup

Store these credentials in a secure location **outside** the repository:

```
# Secure location: Password manager, encrypted USB, or paper in safe
TELEGRAM_BOT_TOKEN=<your_token>
ALLOWED_USERS=<your_user_id>
GMAIL_ADDRESS=<your_email>
GMAIL_APP_PASSWORD=<your_app_password>
```

**Recommended storage:**
- Bitwarden/1Password secure note
- Encrypted file on separate drive
- Printed copy in fireproof safe

### 3.2 Automated Backups

Add to crontab for daily backups:

```bash
# Daily backup at 2am
0 2 * * * /media/jdlongmire/Macro-Drive-2TB/GitHub_Repos/thinx/scripts/backup.sh
```

Create `/media/jdlongmire/Macro-Drive-2TB/GitHub_Repos/thinx/scripts/backup.sh`:

```bash
#!/bin/bash
BACKUP_DIR="/media/jdlongmire/Macro-Drive-2TB/GitHub_Repos/thinx-backups/$(date +%Y-%m-%d)"
THINX_DIR="/media/jdlongmire/Macro-Drive-2TB/GitHub_Repos/thinx"

mkdir -p "$BACKUP_DIR"

# Critical files
cp "$THINX_DIR/thinxai-telegram/.env" "$BACKUP_DIR/"
cp "$THINX_DIR/MEMORY.md" "$BACKUP_DIR/"
cp -r "$THINX_DIR/memory/telegram/" "$BACKUP_DIR/telegram-history/"
cp -r "$THINX_DIR/memory/meta-context/" "$BACKUP_DIR/meta-context/"

# Keep only last 30 days
find /media/jdlongmire/Macro-Drive-2TB/GitHub_Repos/thinx-backups -maxdepth 1 -type d -mtime +30 -exec rm -rf {} \;

echo "Backup completed: $BACKUP_DIR"
```

### 3.3 Export Systemd Service

Save a copy of the service file:

```bash
cp /etc/systemd/system/thinxai-telegram.service \
   /media/jdlongmire/Macro-Drive-2TB/GitHub_Repos/thinx/thinx-recovery/thinxai-telegram.service
```

### 3.4 Export Cron Jobs

Save crontab for recovery:

```bash
crontab -l > /media/jdlongmire/Macro-Drive-2TB/GitHub_Repos/thinx/thinx-recovery/crontab.backup
```

---

## 4. Recovery Procedures

### 4.1 Quick Recovery (Bridge Only)

For simple restart after crash or update:

```bash
# Stop existing
sudo systemctl stop thinxai-telegram

# Pull latest code
cd /media/jdlongmire/Macro-Drive-2TB/GitHub_Repos/thinx
git pull

# Restart
sudo systemctl start thinxai-telegram

# Verify
sudo systemctl status thinxai-telegram
```

### 4.2 Credential Recovery

**Telegram Bot Token:**
1. Open Telegram, message @BotFather
2. Send `/mybots`
3. Select your bot
4. Click "API Token" to view/regenerate

**Gmail App Password:**
1. Go to https://myaccount.google.com/security
2. Under "2-Step Verification" click "App passwords"
3. Generate new password for "Mail" on "Linux"

**Update .env:**
```bash
nano /media/jdlongmire/Macro-Drive-2TB/GitHub_Repos/thinx/thinxai-telegram/.env
```

### 4.3 Full System Recovery

#### Phase 1: System Prerequisites (5 min)

```bash
# Install system packages
sudo apt update
sudo apt install -y python3 python3-pip git msmtp msmtp-mta

# Install Node.js (for Claude CLI)
curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash -
sudo apt install -y nodejs

# Install Claude CLI
npm install -g @anthropic-ai/claude-cli
claude login
```

#### Phase 2: Clone Repository (2 min)

```bash
cd /media/jdlongmire/Macro-Drive-2TB/GitHub_Repos
git clone https://github.com/jdlongmire/thinx.git
cd thinx
```

#### Phase 3: Restore Credentials (3 min)

```bash
# Create .env from backup
cat > thinxai-telegram/.env << 'EOF'
TELEGRAM_BOT_TOKEN=<your_token>
ALLOWED_USERS=<your_user_id>
GMAIL_ADDRESS=<your_email>
GMAIL_APP_PASSWORD=<your_app_password>
EOF
```

#### Phase 4: Install Dependencies (3 min)

```bash
cd thinxai-telegram
pip install -r requirements.txt
```

#### Phase 5: Create Directory Structure (1 min)

```bash
mkdir -p memory/telegram
mkdir -p memory/meta-context/current
mkdir -p memory/meta-context/archive
mkdir -p downloads/telegram
```

#### Phase 6: Restore Systemd Service (3 min)

```bash
sudo cp thinx-recovery/thinxai-telegram.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable thinxai-telegram
sudo systemctl start thinxai-telegram
```

#### Phase 7: Restore Cron Jobs (2 min)

```bash
crontab thinx-recovery/crontab.backup
# Or manually add:
crontab -e
```

Add these entries:
```
# Dashboard update - hourly
0 * * * * /media/jdlongmire/Macro-Drive-2TB/GitHub_Repos/thinx/scripts/update-dashboard.sh >> /tmp/dashboard-update.log 2>&1
# Health email - hourly at :30
30 * * * * /media/jdlongmire/Macro-Drive-2TB/GitHub_Repos/thinx/scripts/health-email.sh >> /tmp/health-email.log 2>&1
# Meta-context daily rotation - midnight
0 0 * * * /media/jdlongmire/Macro-Drive-2TB/GitHub_Repos/thinx/scripts/rotate-meta-context.sh >> /tmp/meta-context-rotate.log 2>&1
# Meta-context quarterly rollup
0 1 1 1,4,7,10 * /media/jdlongmire/Macro-Drive-2TB/GitHub_Repos/thinx/scripts/rotate-meta-context.sh --quarterly >> /tmp/meta-context-rotate.log 2>&1
# Daily backup at 2am
0 2 * * * /media/jdlongmire/Macro-Drive-2TB/GitHub_Repos/thinx/scripts/backup.sh >> /tmp/backup.log 2>&1
```

#### Phase 8: Restore Conversation History (2 min)

If you have backups:
```bash
cp /path/to/backup/telegram-history/*.jsonl memory/telegram/
cp /path/to/backup/MEMORY.md ./MEMORY.md
cp -r /path/to/backup/meta-context/* memory/meta-context/
```

#### Phase 9: Restore VS Code Extension (5 min)

```bash
cd thinxai-vscode
npm install
npm run compile
vsce package
code --install-extension thinxai-chat-0.2.0.vsix
```

### 4.4 Web Chat Recovery

For standalone web chat recovery:

```bash
# Install dependencies
cd thinxai-web
pip install aiohttp

# Create .env for email (optional)
cat > .env << 'EOF'
GMAIL_ADDRESS=your_gmail@gmail.com
GMAIL_APP_PASSWORD=your_app_password_here
EOF

# Start web chat
python3 web_chat.py --host 0.0.0.0 --port 8088

# Or run in background
nohup python3 web_chat.py --host 0.0.0.0 --port 8088 > /tmp/web_chat.log 2>&1 &
```

**Verify:**
- Open http://localhost:8088
- Send a test message
- Check `/api/status` endpoint

### 4.5 Security Incident

If credentials are compromised:

**Immediate Actions (< 5 minutes):**

```bash
# 1. Stop the bridge
sudo systemctl stop thinxai-telegram

# 2. Revoke Telegram token
# Message @BotFather: /revoke -> select bot -> confirm

# 3. Revoke Gmail app password
# Google Account -> Security -> App passwords -> Delete all

# 4. Generate new credentials
# @BotFather: /token -> select bot -> new token
# Google Account -> App passwords -> Generate new

# 5. Update .env with new credentials
nano thinxai-telegram/.env

# 6. Restart
sudo systemctl start thinxai-telegram
```

**Post-Incident:**
- Review logs: `journalctl -u thinxai-telegram --since "1 hour ago"`
- Check conversation history for unauthorized access
- Review email sent folder for unauthorized sends

---

## 5. Validation Checklist

Run after any recovery to confirm system health:

### Bridge Health

```bash
# Service running
systemctl is-active thinxai-telegram
# Expected: active

# Process exists
pgrep -f "python3 bridge.py"
# Expected: PID number

# HTTP API responds
curl -s http://localhost:18789/api/status | jq .
# Expected: {"status": "online", ...}

# Logs show activity
tail -5 /tmp/bridge.log
# Expected: Recent timestamps, no errors
```

### Telegram Connectivity

1. Send `/start` to bot in Telegram
2. Expected: Help message response
3. Send "Hello"
4. Expected: Claude response

### Web Chat Health

```bash
# Process running
pgrep -f "web_chat.py"
# Expected: PID number

# HTTP API responds
curl -s http://localhost:8088/api/status | jq .
# Expected: {"status": "ok", ...}
```

1. Open http://localhost:8088 in browser
2. Send a test message
3. Expected: Claude response with streaming

### Gmail Integration

1. Send "Check my email" via Telegram
2. Expected: Inbox summary or "no new emails"

### VS Code Extension

1. Open VS Code
2. Open ThinxAI Chat panel
3. Send a message
4. Expected: Response appears with "VS Code" badge

### Cron Jobs

```bash
# List all jobs
crontab -l | grep thinx
# Expected: 5 entries (dashboard, health, rotate-daily, rotate-quarterly, backup)

# Check last run (wait for scheduled time)
cat /tmp/dashboard-update.log | tail -5
cat /tmp/health-email.log | tail -5
```

### Memory System

```bash
# Shared memory exists
test -f MEMORY.md && echo "OK" || echo "MISSING"

# Conversation history writable
touch memory/telegram/test.txt && rm memory/telegram/test.txt && echo "OK"

# Meta-context structure
ls memory/meta-context/current/
# Expected: telegram-bridge.md, vscode-claude.md
```

---

## 6. Maintenance Schedule

### Daily
- [ ] Verify health email received (7:30 AM)
- [ ] Check dashboard updates on thinxai.net

### Weekly
- [ ] Review `/tmp/bridge.log` for errors
- [ ] Check disk usage on backup drive
- [ ] Test Telegram bot responsiveness

### Monthly
- [ ] Verify backup script runs correctly
- [ ] Test credential recovery procedure
- [ ] Update this document if system changes
- [ ] Export fresh crontab backup

### Quarterly
- [ ] Full recovery drill (spin up on test machine)
- [ ] Review and rotate credentials
- [ ] Archive old meta-context files
- [ ] Clean up old session logs

---

## Quick Reference Card

```
┌─────────────────────────────────────────────────────────────┐
│                    THINXAI QUICK RECOVERY                    │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  CHECK STATUS                                                │
│    sudo systemctl status thinxai-telegram                    │
│    curl localhost:18789/api/status                           │
│                                                              │
│  RESTART                                                     │
│    sudo systemctl restart thinxai-telegram                   │
│                                                              │
│  VIEW LOGS                                                   │
│    journalctl -u thinxai-telegram -f                         │
│    tail -f /tmp/bridge.log                                   │
│                                                              │
│  FULL RECOVERY                                               │
│    1. git clone https://github.com/jdlongmire/thinx.git      │
│    2. Restore .env credentials                               │
│    3. pip install -r thinxai-telegram/requirements.txt       │
│    4. Restore systemd service                                │
│    5. Restore crontab                                        │
│    6. systemctl start thinxai-telegram                       │
│                                                              │
│  CREDENTIAL RECOVERY                                         │
│    Telegram: @BotFather → /mybots → API Token                │
│    Gmail: myaccount.google.com → Security → App passwords    │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-01-31 | Claude/JD | Initial comprehensive plan |
| 1.1 | 2026-02-03 | Claude/JD | Added thinxai-web, hardware specs, 5th cron job, CURRENT-ARCHITECTURE.md link |
