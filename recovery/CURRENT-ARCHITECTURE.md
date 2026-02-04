# ThinxAI Current Architecture

**Last Updated:** 2026-02-03
**Machine:** Dell OptiPlex 3050 (thinxai-workstation)

---

## Hardware Specifications

| Component | Details |
|-----------|---------|
| **System** | Dell OptiPlex 3050 Desktop |
| **OS** | Ubuntu 22.04.5 LTS |
| **Kernel** | 6.8.0-94-generic |
| **CPU** | Intel Core i5-7500 @ 3.40GHz (4 cores, no HT) |
| **RAM** | 16 GB |
| **GPU** | Intel HD Graphics 630 (integrated) |

### Storage Layout

| Drive | Size | Mount | Filesystem | Purpose |
|-------|------|-------|------------|---------|
| sda (SSD) | 238 GB | `/` | ext4 | Ubuntu system (118 GB partition) |
| sda3 | 119 GB | - | ntfs | Windows partition (dual-boot) |
| sdb (HDD) | 1.8 TB | `/media/jdlongmire/Macro-Drive-2TB` | ntfs | Data/GitHub repos |

---

## Network Services

| Port | Process | Host Binding | Purpose |
|------|---------|--------------|---------|
| **8088** | `web_chat.py` | `0.0.0.0` | ThinxAI Web Chat (standalone) |
| **8080** | Node.js | `100.108.64.24` (Tailscale) | Node application |
| **18789** | `bridge.py` | `127.0.0.1` + Tailscale | Telegram Bridge HTTP API |

### Tailscale

- IP: `100.108.64.24`
- Provides secure remote access to local services

---

## Active Services

### 1. Telegram Bridge (`bridge.py`)

**Location:** `/path/to/thinx/thinxai-telegram/`

**Purpose:** Routes Telegram messages to Claude CLI, handles email integration.

**Start command:**
```bash
cd /path/to/thinx/thinxai-telegram
nohup python3 bridge.py > /tmp/bridge.log 2>&1 &
```

**HTTP API:** `http://localhost:18789/api/status`

**Dependencies:**
- Python 3.10+
- aiohttp, python-telegram-bot
- Claude CLI (`claude` command)

**Credentials:** `thinxai-telegram/.env`
```
TELEGRAM_BOT_TOKEN=<bot_token>
ALLOWED_USERS=<telegram_user_id>
GMAIL_ADDRESS=<email>
GMAIL_APP_PASSWORD=<app_password>
```

### 2. Web Chat (`web_chat.py`)

**Location:** `/path/to/thinx/thinxai-web/`

**Purpose:** Standalone web interface for Claude CLI - no Telegram dependency.

**Start command:**
```bash
cd /path/to/thinx/thinxai-web
python3 web_chat.py --host 0.0.0.0 --port 8088
```

**URL:** `http://localhost:8088`

**Features:**
- SSE streaming responses
- File uploads (20MB limit)
- Image display with fullscreen modal
- Conversation history (JSONL)
- Shared MEMORY.md context

**Credentials:** `thinxai-web/.env`
```
GMAIL_ADDRESS=<email>
GMAIL_APP_PASSWORD=<app_password>
```

---

## Cron Jobs (User: jdlongmire)

| Schedule | Script | Log | Purpose |
|----------|--------|-----|---------|
| `0 * * * *` | `update-dashboard.sh` | `/tmp/dashboard-update.log` | Hourly dashboard update |
| `30 * * * *` | `health-email.sh` | `/tmp/health-email.log` | Hourly health status email |
| `0 0 * * *` | `rotate-meta-context.sh` | `/tmp/meta-context-rotate.log` | Daily meta-context rotation |
| `0 1 1 1,4,7,10 *` | `rotate-meta-context.sh --quarterly` | `/tmp/meta-context-rotate.log` | Quarterly archive rollup |
| `0 2 * * *` | `backup.sh` | `/tmp/backup.log` | Daily backup at 2am |

**Scripts location:** `/path/to/thinx/scripts/`

---

## Directory Structure

```
/path/to/thinx/
├── CLAUDE.md                    # Agent instructions (session init)
├── MEMORY.md                    # Standing context (shared)
├── memory/
│   ├── meta-context/
│   │   ├── current/            # Today's activity logs
│   │   │   ├── telegram-bridge.md
│   │   │   └── vscode-claude.md
│   │   └── archive/            # Historical logs
│   └── telegram/               # Telegram chat history (gitignored)
├── thinxai-telegram/           # Telegram bridge
│   ├── bridge.py
│   ├── requirements.txt
│   └── .env                    # Credentials (gitignored)
├── thinxai-web/                # Standalone web chat
│   ├── web_chat.py
│   ├── email_utils.py
│   ├── web/index.html
│   ├── history/                # Web chat history
│   ├── downloads/              # Uploaded files
│   └── .env                    # Email credentials (gitignored)
├── scripts/
│   ├── backup.sh
│   ├── health-email.sh
│   ├── update-dashboard.sh
│   ├── rotate-meta-context.sh
│   └── setup-new-machine.sh
├── thinx-recovery/             # Disaster recovery docs
│   ├── DISASTER-RECOVERY-PLAN.md
│   ├── CURRENT-ARCHITECTURE.md  # This file
│   ├── QUICKSTART.md
│   ├── README.md
│   ├── crontab.backup
│   └── thinxai-telegram.service
└── research-programs/          # Research domains
    ├── ai-research/
    ├── logic-realism/
    ├── oddxian/
    └── MS-Applied-AI/
```

---

## Email Configuration

### msmtp (System SMTP)

**Config file:** `~/.msmtprc`

**Account:** ThinxAI.jdl@gmail.com

Used by:
- `health-email.sh` (cron)
- `email_utils.py` (web chat)
- Any script needing to send email

### Gmail Integration

Both Telegram bridge and web chat can:
- Read inbox via IMAP
- Send emails via SMTP
- Require Google App Password (not regular password)

---

## Claude Code Configuration

### Global Settings

**Location:** `~/.claude/settings.local.json`

Contains tool permissions (Bash, Edit, Read, MCP tools, etc.)

### Project-Specific

**Location:** `/path/to/thinx/.claude/`

Contains:
- hooks/ (session start, etc.)
- Project-level settings

---

## Recovery Quick Reference

### Check All Services

```bash
# Telegram bridge
pgrep -f "bridge.py" && curl -s localhost:18789/api/status | jq .

# Web chat
pgrep -f "web_chat.py" && curl -s localhost:8088/api/status | jq .

# Cron jobs
crontab -l | grep thinx
```

### Restart Services

```bash
# Telegram bridge
pkill -f "bridge.py"
cd /path/to/thinx/thinxai-telegram
nohup python3 bridge.py > /tmp/bridge.log 2>&1 &

# Web chat
pkill -f "web_chat.py"
cd /path/to/thinx/thinxai-web
nohup python3 web_chat.py --host 0.0.0.0 --port 8088 > /tmp/web_chat.log 2>&1 &
```

### View Logs

```bash
tail -f /tmp/bridge.log       # Telegram bridge
tail -f /tmp/web_chat.log     # Web chat (if redirected)
tail -f /tmp/health-email.log # Hourly health emails
tail -f /tmp/backup.log       # Daily backups
```

---

## Document History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-02-03 | Initial architecture snapshot |
