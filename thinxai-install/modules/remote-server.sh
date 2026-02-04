#!/bin/bash
# ThinxAI Remote Server Module
# Configure task spawning on remote machines in your network

set -e

INSTALL_DIR="${THINXAI_DIR:-$HOME/.thinxai}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
info() { echo -e "${CYAN}[i]${NC} $1"; }

echo ""
echo "═══ Remote Server Module ═══"
echo ""

# Create configuration directory
mkdir -p "$INSTALL_DIR/config/remote"

# Guide for Tailscale setup
cat > "$INSTALL_DIR/config/remote/SETUP.md" << 'REMOTEMD'
# Remote Server Integration

ThinxAI can spawn tasks on remote machines in your Tailscale network.
This enables distributed workloads, always-on services, and local LLM hosting.

## Why Tailscale?

- **Zero-config networking**: Devices find each other automatically
- **No port forwarding**: Works behind NAT, firewalls, carrier-grade NAT
- **Encrypted by default**: WireGuard-based, modern crypto
- **MagicDNS**: Use hostnames like `my-server.tailnet` instead of IPs
- **Free tier**: Up to 100 devices, 3 users

## Setup Steps

### 1. Install Tailscale on Both Machines

```bash
# On your workstation AND remote server
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

### 2. Configure SSH Access

```bash
# Generate key if you don't have one
ssh-keygen -t ed25519 -C "thinxai-remote"

# Copy to remote server (use Tailscale hostname)
ssh-copy-id user@your-server.tailnet

# Test connection
ssh user@your-server.tailnet "echo 'Connected!'"
```

### 3. Update Credentials

Edit `~/.thinxai/config/credentials.env`:

```bash
REMOTE_HOST="your-server.tailnet"  # Or Tailscale IP
REMOTE_USER="your-username"
REMOTE_SSH_KEY="~/.ssh/id_ed25519"
```

### 4. Optional: Install Ollama for Local LLMs

On the remote server:

```bash
# Install Ollama
curl -fsSL https://ollama.ai/install.sh | sh

# Pull a model
ollama pull llama3.2

# Ollama runs on port 11434 by default
```

Add to credentials:

```bash
OLLAMA_HOST="http://your-server.tailnet:11434"
```

## Using Remote Tasks

Once configured, ThinxAI can:

- Run long-running processes on the server
- Execute compute-heavy tasks remotely
- Query local LLMs via Ollama
- Access server resources (databases, files, etc.)

Example commands in Claude Code:

```
"Run this backup script on the server"
"Check disk space on my remote machine"
"Query the local Ollama model about..."
```

## Security Notes

- Tailscale encrypts all traffic between devices
- SSH keys should be password-protected for extra security
- Consider Tailscale ACLs for fine-grained access control
- Remote commands run as your user - same permissions as SSH

## Alternatives to Tailscale

If you prefer not to use Tailscale:

- **ZeroTier**: Similar mesh VPN approach
- **Netbird**: Open-source, self-hostable
- **WireGuard direct**: Maximum control, more manual setup
- **SSH tunnel**: Simple but less convenient

REMOTEMD

# Create helper script for testing remote connection
cat > "$INSTALL_DIR/config/remote/test-connection.sh" << 'TESTSH'
#!/bin/bash
# Test remote server connection

source ~/.thinxai/config/credentials.env 2>/dev/null

if [ -z "$REMOTE_HOST" ]; then
    echo "Error: REMOTE_HOST not configured"
    echo "Edit ~/.thinxai/config/credentials.env"
    exit 1
fi

echo "Testing connection to $REMOTE_HOST..."

SSH_OPTS=""
if [ -n "$REMOTE_SSH_KEY" ]; then
    SSH_OPTS="-i ${REMOTE_SSH_KEY/#\~/$HOME}"
fi

ssh $SSH_OPTS "${REMOTE_USER:-$USER}@$REMOTE_HOST" "
    echo '=== Connection successful ==='
    echo \"Hostname: \$(hostname)\"
    echo \"Uptime: \$(uptime -p)\"
    echo \"User: \$(whoami)\"

    if command -v ollama &> /dev/null; then
        echo ''
        echo '=== Ollama Status ==='
        ollama list 2>/dev/null || echo 'Ollama installed but no models'
    fi
"
TESTSH
chmod +x "$INSTALL_DIR/config/remote/test-connection.sh"

log "Remote server module installed"
echo ""
info "Documentation: $INSTALL_DIR/config/remote/SETUP.md"
info "Test script: $INSTALL_DIR/config/remote/test-connection.sh"
echo ""
echo "Quick start:"
echo "  1. Install Tailscale: curl -fsSL https://tailscale.com/install.sh | sh"
echo "  2. Configure credentials.env with REMOTE_HOST, REMOTE_USER"
echo "  3. Test: bash $INSTALL_DIR/config/remote/test-connection.sh"
echo ""
