# ThinxAI Recovery Package

Complete disaster recovery for ThinxAI environment from a fresh Ubuntu install.

**See also:**
- [DISASTER-RECOVERY-PLAN.md](DISASTER-RECOVERY-PLAN.md) - Detailed procedures, scenarios, validation checklists
- [CURRENT-ARCHITECTURE.md](CURRENT-ARCHITECTURE.md) - Live system configuration snapshot

---

## What This Restores

| Component | Description |
|-----------|-------------|
| Claude Code CLI | AI coding assistant |
| VS Code + Extension | IDE with Claude integration |
| Custom Skills | `/generate-image` DALL-E skill |
| Cron Jobs | Health emails, dashboard updates, backups, meta-context rotation |
| Telegram Bridge | Message bridge dependencies |
| Web Chat Interface | Standalone web UI for Claude CLI |
| All Repositories | thinx, dashboard, research repos |
| MCP Permissions | Legato and other tool permissions |

---

## Quick Recovery (Automated)

### 1. Mount USB Drive

```bash
# Find the drive
lsblk

# Mount (Ubuntu usually auto-mounts to /media/$USER/Macro-Drive-2TB)
```

### 2. Run Setup Script

```bash
cd /path/to/thinx-recovery
bash setup.sh
```

> **Note:** Replace `/path/to/thinx-recovery` with wherever you downloaded or cloned this folder.

### 3. Configure Credentials

```bash
nano ~/.thinxai-credentials
```

Fill in:
- `ANTHROPIC_API_KEY` - Get from console.anthropic.com
- `OPENAI_API_KEY` - Get from platform.openai.com
- `GMAIL_APP_PASSWORD` - Create at myaccount.google.com/apppasswords
- `TELEGRAM_BOT_TOKEN` - Create via @BotFather (optional)

### 4. Reload Environment

```bash
source ~/.bashrc
```

### 5. Authenticate Services

```bash
# GitHub
gh auth login

# Claude Code (first run authenticates)
cd ~/GitHub_Repos/thinx
claude
```

---

## Manual Recovery

For step-by-step manual recovery, see [DISASTER-RECOVERY-PLAN.md](DISASTER-RECOVERY-PLAN.md), Section 4.3.

---

## Post-Recovery Setup

### Telegram Bridge (Optional)

```bash
cd ~/GitHub_Repos/thinx/thinxai-telegram

# Create .env file
cat > .env << 'EOF'
TELEGRAM_BOT_TOKEN=your-token
TELEGRAM_ALLOWED_USER_IDS=your-user-id
ANTHROPIC_API_KEY=your-key
GMAIL_ADDRESS=ThinxAI.jdl@gmail.com
GMAIL_APP_PASSWORD=your-app-password
EOF

# Test
python3 bridge.py
```

### Web Chat Interface (Optional)

```bash
cd ~/GitHub_Repos/thinx/thinxai-web

# Run manually
python3 web_chat.py --port 8080
# Open http://localhost:8080

# Or install as systemd service
sudo cp thinx-recovery/thinxai-web.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now thinxai-web
```

---

## Verify Recovery

```bash
# Check installations
node --version          # v20+
gh --version           # gh 2.x
claude --version       # claude-code
code --version         # VS Code

# Check cron jobs
crontab -l

# Test Claude Code
cd ~/GitHub_Repos/thinx
claude
# Should see Agent ID in session start
```

For full validation checklist, see [DISASTER-RECOVERY-PLAN.md](DISASTER-RECOVERY-PLAN.md), Section 5.

---

## Directory Structure After Recovery

```
~/GitHub_Repos/
├── thinx/                      # Main workspace
│   ├── CLAUDE.md              # Agent instructions
│   ├── MEMORY.md              # Shared memory
│   ├── memory/meta-context/   # Cross-agent awareness
│   ├── thinxai-telegram/      # Telegram bridge
│   ├── thinxai-web/           # Web chat interface
│   └── scripts/               # Automation scripts
├── thinx-dashboard/           # Public dashboard
├── AI-Research/               # AIDK Framework
├── oddxian-apologetics/       # Apologetics
├── logic-realism-theory/      # LRT
└── thinxai.net/              # ThinxAI website

~/.claude/
├── settings.local.json        # Permissions
└── skills/                    # Custom skills
```

---

## Credentials You Need

| Credential | Where to Get | Used For |
|------------|--------------|----------|
| ANTHROPIC_API_KEY | console.anthropic.com | Claude Code |
| OPENAI_API_KEY | platform.openai.com | DALL-E images |
| GMAIL_APP_PASSWORD | myaccount.google.com/apppasswords | Health emails |
| TELEGRAM_BOT_TOKEN | @BotFather on Telegram | Bridge |
| GitHub Auth | `gh auth login` | Repo access |

---

## What's NOT Restored Automatically

- API keys (you re-enter these)
- Telegram bot (create new via @BotFather)
- Gmail app password (create new)
- Conversation history from previous machine
- Local backup history

---

## Recovery Files

```
thinx-recovery/
├── README.md                  # This file
├── DISASTER-RECOVERY-PLAN.md  # Detailed procedures
├── CURRENT-ARCHITECTURE.md    # System configuration snapshot
├── setup.sh                   # Automated setup script
├── crontab.backup             # Cron jobs backup
├── config/
│   ├── settings.local.json    # Claude permissions
│   ├── credentials-template.env
│   └── skills/
│       └── generate-image.md  # DALL-E skill
├── templates/
│   ├── CLAUDE.md              # Agent instructions
│   └── MEMORY.md              # Shared memory
└── thinxai-web/               # Web chat interface
    ├── web_chat.py            # Server script
    ├── README.md              # Usage docs
    └── web/
        ├── index.html         # Chat UI
        └── avatar.png         # Logo (gitignored)
```

---

## Troubleshooting

**Claude Code not found after install:**
```bash
source ~/.nvm/nvm.sh
npm install -g @anthropic-ai/claude-code
```

**Cron jobs not running:**
```bash
# Check cron daemon
systemctl status cron

# Check logs
grep CRON /var/log/syslog | tail -20
```

**Health emails failing:**
```bash
# Test manually
~/GitHub_Repos/thinx/scripts/health-email.sh

# Check Gmail app password is correct
```

**Hooks not running:**
```bash
chmod +x ~/GitHub_Repos/thinx/.claude/hooks/*.sh
```

---

## Optional: Oracle Cloud CLI

See `oci-setup.sh` for installation and usage (separate optional component).
