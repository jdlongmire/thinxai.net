# ThinxAI

**Agentic Orchestrator & Local Sysadmin Framework**

ThinxAI is a locally-hosted AI assistant framework that handles system administration, automation, and cross-device coordination while keeping your data on your hardware.

## What You Get

- **AI-powered system management** with human oversight
- **Multi-device coordination** via Tailscale mesh networking
- **Multiple interfaces**: Terminal, Telegram, Web Chat
- **Automated monitoring** and reporting
- **Privacy-first**: Your data stays on your hardware

## Quick Install

```bash
curl -fsSL https://thinxai.net/install | bash
```

Or clone and run:

```bash
git clone https://github.com/jdlongmire/thinxai.net.git
cd thinxai.net/thinxai-install
bash install.sh
```

## Requirements

- **OS**: Ubuntu 22.04+ (Debian-based Linux)
- **API Key**: Anthropic API key (for Claude)
- **Optional**: Tailscale account for multi-device setup
- **Optional**: Additional server for distributed tasks

## Philosophy: Human-Curated, AI-Enabled (HCAE)

ThinxAI follows the HCAE model:

- **You make decisions**, AI executes
- **All automation requires explicit approval**
- **Transparency over magic**
- **Your data, your hardware, your control**

## Components

### Core (Always Installed)

- **Claude Code CLI**: The AI agent backbone
- **Meta-context system**: Session awareness and cross-agent coordination
- **Git integration**: Repository management and version control
- **Python virtual environment**: Isolated dependencies at `~/.thinxai/venv`
- **Basic automation**: Cron job templates for monitoring

### Interface Modules (Optional)

| Module | Description | Access Method |
|--------|-------------|---------------|
| **Telegram Bot** | Mobile access to your agent | Telegram app |
| **Web Chat** | Browser-based interface | `http://localhost:8080` |
| **Remote Server** | Task spawning on network machines | SSH over Tailscale |

## Installation Modes

```bash
# Interactive (recommended) - choose what to install
bash install.sh

# Minimal - core only
bash install.sh --minimal

# Full - all components
bash install.sh --full

# Non-interactive
bash install.sh --full --no-confirm

# Dry run - see what would be installed without making changes
bash install.sh --full --dry-run
```

## Post-Installation

### 1. Configure Credentials

```bash
nano ~/.thinxai/config/credentials.env
```

Required:
- `ANTHROPIC_API_KEY` - Get from [Anthropic Console](https://console.anthropic.com/)

Optional:
- `THINXAI_CLAUDE_MODEL` - Model to use (default: `claude-sonnet-4-20250514`)
- `TELEGRAM_BOT_TOKEN` - Create via [@BotFather](https://t.me/BotFather)
- `THINXAI_WEB_HOST` / `THINXAI_WEB_PORT` - Web interface binding (default: `127.0.0.1:8080`)
- `GMAIL_ADDRESS` / `GMAIL_APP_PASSWORD` - For email notifications
- `REMOTE_HOST` / `REMOTE_USER` - For server integration

### 2. Authenticate

```bash
# Reload shell
source ~/.bashrc

# GitHub (for repo management)
gh auth login

# Claude Code (first run)
cd ~/GitHub_Repos/thinxai && claude
```

### 3. Start Interfaces

```bash
# Activate the virtual environment first
source ~/.thinxai/venv/bin/activate

# Web Chat
python3 ~/GitHub_Repos/thinxai/web-chat/web_chat.py

# Telegram Bot
python3 ~/GitHub_Repos/thinxai/telegram-bridge/telegram_bot.py
```

## Multi-Device Setup with Tailscale

ThinxAI recommends [Tailscale](https://tailscale.com/) for connecting multiple machines:

```bash
# Install on each device
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

Benefits:
- Zero-config mesh networking
- Works through NAT/firewalls
- Encrypted by default (WireGuard)
- Free tier: 100 devices, 3 users

See `~/.thinxai/config/remote/SETUP.md` for detailed instructions.

## Directory Structure

```
~/.thinxai/
├── config/
│   ├── credentials.env     # API keys and secrets
│   ├── thinxai-web.service # Systemd service templates
│   ├── thinxai-telegram.service
│   └── remote/
│       └── SETUP.md        # Remote server guide
├── logs/                   # Activity logs
├── modules/                # Installed modules
└── venv/                   # Python virtual environment

~/GitHub_Repos/thinxai/
├── telegram-bridge/        # Telegram bot
├── web-chat/               # Web interface
├── memory/                 # Cross-agent context
└── scripts/                # Automation scripts
```

## Systemd Services (Optional)

Run interfaces as system services:

```bash
# Web Chat
sudo cp ~/.thinxai/config/thinxai-web.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now thinxai-web

# Telegram Bot
sudo cp ~/.thinxai/config/thinxai-telegram.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now thinxai-telegram
```

## Configuration Options

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `ANTHROPIC_API_KEY` | Required API key | - |
| `THINXAI_CLAUDE_MODEL` | Claude model to use | `claude-sonnet-4-20250514` |
| `THINXAI_WEB_HOST` | Web server bind address | `127.0.0.1` |
| `THINXAI_WEB_PORT` | Web server port | `8080` |
| `TELEGRAM_BOT_TOKEN` | Telegram bot token | - |
| `TELEGRAM_ALLOWED_USERS` | Comma-separated user IDs | - |
| `REMOTE_HOST` | Remote server hostname | - |
| `REMOTE_USER` | Remote SSH username | - |
| `REMOTE_SSH_KEY` | Path to SSH key | `~/.ssh/id_ed25519` |
| `OLLAMA_HOST` | Ollama API endpoint | - |

## Security Considerations

- **Credentials**: Stored in `~/.thinxai/config/credentials.env` with 600 permissions
- **API access**: Claude API calls go directly to Anthropic; no data stored externally
- **Local-first**: All processing happens on your machines
- **Network**: Tailscale encrypts all cross-device traffic
- **Permissions**: Claude Code respects configured allow/deny rules
- **Python isolation**: Dependencies installed in venv, not system-wide

## Caveats

1. **Not autonomous**: All actions require human approval or explicit standing instructions
2. **Fallible**: AI can make mistakes; validation is built into the workflow
3. **API costs**: Claude API usage incurs standard Anthropic pricing
4. **Linux-focused**: Tested on Ubuntu/Debian; other distros may need adjustments

## Support

- **Documentation**: https://thinxai.net/docs
- **Issues**: https://github.com/jdlongmire/thinxai.net/issues
- **Updates**: `cd ~/GitHub_Repos/thinxai && git pull`

## License

MIT License - see [LICENSE](LICENSE)

---

*ThinxAI: Your infrastructure, your control, AI-enabled.*
