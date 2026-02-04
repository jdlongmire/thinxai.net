# ThinxAI

**Agentic Orchestrator & Local Sysadmin Framework**

A locally-hosted AI assistant framework that handles system administration, automation, and cross-device coordination while keeping your data on your hardware.

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
