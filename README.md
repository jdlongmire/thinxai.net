# ThinxAI

**Agentic Orchestrator & Local Sysadmin Framework**

A locally-hosted AI assistant framework that handles system administration, automation, and cross-device coordination while keeping your data on your hardware.

## ⚠️ Risk Warning

**This is a HIGH-RISK installation.** ThinxAI gives an AI assistant significant control over your system:

| Risk | Description |
|------|-------------|
| **System Access** | Claude Code can execute arbitrary shell commands on your machine |
| **File Access** | AI can read, modify, and delete files across your filesystem |
| **Credential Exposure** | Installation stores API keys, email credentials, and tokens in plain text config files |
| **Remote Execution** | Telegram bridge enables remote command execution from mobile |
| **No Sandbox** | Commands run with your user's full permissions (sudo if available) |
| **Pipe to Bash** | The curl install method executes remote code without prior inspection |

**This framework is designed for power users who understand these risks and want AI-assisted system administration anyway.** If you're uncomfortable with any of the above, this project is not for you.

### Mitigation

- Run on a dedicated machine or VM, not your primary workstation
- Use a non-sudo user account where possible
- Review all scripts before running (`git clone` then inspect)
- Monitor `~/.thinxai/logs/` for executed commands
- Never expose the web interface to the internet without authentication

---

## Quick Install

```bash
curl -fsSL https://thinxai.net/install | bash
```

This installer:
- Shows what it will do before executing
- Prompts for confirmation (default: No)
- Provides instructions for manual review

To review the script first:
```bash
curl -fsSL https://thinxai.net/install > install.sh
less install.sh
bash install.sh
```

## What You Get

- **AI-powered system management** with human oversight
- **Multi-device coordination** via Tailscale mesh networking
- **Multiple interfaces**: Terminal (Claude Code), Telegram, Web Chat
- **Automated monitoring** and reporting
- **Privacy-first**: Your data stays on your hardware

## Requirements

- **OS**: Ubuntu 22.04+ (Debian-based Linux)
- **API Key**: Anthropic API key ([console.anthropic.com](https://console.anthropic.com/))
- **Optional**: Tailscale account for multi-device setup

## Philosophy: Human-Curated, AI-Enabled

ThinxAI follows the HCAE model:

- You make decisions, AI executes
- All automation requires explicit approval
- Transparency over magic
- Your data, your hardware, your control

## Documentation

See the [Installation Guide](thinxai-install/README.md) for detailed documentation including:

- Installation modes (minimal, full, interactive)
- Post-installation configuration
- Multi-device setup with Tailscale
- Systemd service configuration
- Environment variables reference

## Repository Structure

```
thinxai.net/
├── index.html              # Landing page
├── install                 # Bootstrap script (served at /install)
├── thinxai-install/        # Full installer and documentation
│   ├── install.sh          # Main installation script
│   ├── modules/            # Modular installation scripts
│   ├── config/             # Configuration templates
│   └── README.md           # Detailed documentation
└── README.md               # This file
```

## Support

- **Issues**: [GitHub Issues](https://github.com/jdlongmire/thinxai.net/issues)
- **Website**: [thinxai.net](https://thinxai.net)

## License

MIT License - see [LICENSE](thinxai-install/LICENSE)

---

*Your infrastructure, your control, AI-enabled.*
