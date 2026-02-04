#!/bin/bash
# ThinxAI Installer
# Agentic Orchestrator & Local Sysadmin Framework
#
# Usage:
#   curl -fsSL https://thinxai.net/install | bash
#   OR
#   bash install.sh [--minimal|--full] [--no-confirm] [--dry-run]
#
# This installer sets up ThinxAI on your local machine with
# human-curated, AI-enabled automation capabilities.

set -e

VERSION="1.1.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)" || SCRIPT_DIR="$(pwd)"
GITHUB_RAW="https://raw.githubusercontent.com/jdlongmire/thinxai.net/main/thinxai-install"
INSTALL_DIR="$HOME/.thinxai"
REPOS_DIR="$HOME/GitHub_Repos"
VENV_DIR="$INSTALL_DIR/venv"

# Export for module scripts
export THINXAI_DIR="$INSTALL_DIR"
export THINXAI_REPO="$REPOS_DIR/thinxai"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Logging
log()     { echo -e "${GREEN}[✓]${NC} $1"; }
warn()    { echo -e "${YELLOW}[!]${NC} $1"; }
error()   { echo -e "${RED}[✗]${NC} $1"; exit 1; }
info()    { echo -e "${CYAN}[i]${NC} $1"; }
section() { echo -e "\n${BOLD}${CYAN}═══ $1 ═══${NC}\n"; }

# Dry run mode
dry_run() {
    if [ "$DRY_RUN" == true ]; then
        echo -e "${YELLOW}[DRY RUN]${NC} Would execute: $*"
        return 0
    else
        "$@"
    fi
}

# Parse arguments
INSTALL_MODE="interactive"
NO_CONFIRM=false
DRY_RUN=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --minimal) INSTALL_MODE="minimal"; shift ;;
        --full)    INSTALL_MODE="full"; shift ;;
        --no-confirm) NO_CONFIRM=true; shift ;;
        --dry-run) DRY_RUN=true; shift ;;
        --help|-h)
            echo "ThinxAI Installer v$VERSION"
            echo ""
            echo "Usage: bash install.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --minimal     Install core only (no interfaces)"
            echo "  --full        Install all components"
            echo "  --no-confirm  Skip confirmation prompts"
            echo "  --dry-run     Show what would be done without executing"
            echo "  --help        Show this help"
            exit 0
            ;;
        *) shift ;;
    esac
done

# Banner
clear
cat << 'EOF'
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║   ████████╗██╗  ██╗██╗███╗   ██╗██╗  ██╗ █████╗ ██╗             ║
║   ╚══██╔══╝██║  ██║██║████╗  ██║╚██╗██╔╝██╔══██╗██║             ║
║      ██║   ███████║██║██╔██╗ ██║ ╚███╔╝ ███████║██║             ║
║      ██║   ██╔══██║██║██║╚██╗██║ ██╔██╗ ██╔══██║██║             ║
║      ██║   ██║  ██║██║██║ ╚████║██╔╝ ██╗██║  ██║██║             ║
║      ╚═╝   ╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝             ║
║                                                                  ║
║            Agentic Orchestrator & Local Sysadmin                 ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
EOF
echo ""
echo "  Version: $VERSION"
echo "  Website: https://thinxai.net"
[ "$DRY_RUN" == true ] && echo -e "  Mode: ${YELLOW}DRY RUN${NC}"
echo ""

# Check prerequisites
section "Checking Prerequisites"

check_command() {
    if command -v "$1" &> /dev/null; then
        log "$1 found"
        return 0
    else
        warn "$1 not found"
        return 1
    fi
}

# Required
if [ "$EUID" -eq 0 ]; then
    error "Do not run as root. Run as your normal user."
fi

MISSING_REQUIRED=()
check_command "git" || MISSING_REQUIRED+=("git")
check_command "curl" || MISSING_REQUIRED+=("curl")

if [ ${#MISSING_REQUIRED[@]} -gt 0 ]; then
    echo ""
    error "Missing required tools: ${MISSING_REQUIRED[*]}\nInstall with: sudo apt install ${MISSING_REQUIRED[*]}"
fi

# Optional (will be installed)
NEEDS_INSTALL=()
check_command "node" || NEEDS_INSTALL+=("nodejs")
check_command "python3" || NEEDS_INSTALL+=("python3")
check_command "gh" || NEEDS_INSTALL+=("gh")
check_command "claude" || NEEDS_INSTALL+=("claude-code")

# Explain what ThinxAI is
section "What is ThinxAI?"

cat << 'EOF'
ThinxAI is a locally-hosted AI assistant framework that:

  • Uses Claude Code as the core agent
  • Handles system administration and automation
  • Coordinates across multiple devices via Tailscale
  • Keeps your data on YOUR hardware

Philosophy: Human-Curated, AI-Enabled (HCAE)
  • You make decisions, AI executes
  • All automation requires explicit approval
  • Transparency over magic

EOF

# Component selection
section "Select Components"

INSTALL_CORE=true
INSTALL_TELEGRAM=false
INSTALL_WEB=false
INSTALL_REMOTE=false

if [ "$INSTALL_MODE" == "minimal" ]; then
    info "Minimal mode: Core only"
elif [ "$INSTALL_MODE" == "full" ]; then
    info "Full mode: All components"
    INSTALL_TELEGRAM=true
    INSTALL_WEB=true
else
    # Interactive selection
    echo "Select which components to install:"
    echo ""
    echo -e "  ${GREEN}[x]${NC} Core (Claude Code + meta-context)     ${YELLOW}[required]${NC}"
    echo ""

    if [ "$NO_CONFIRM" == false ]; then
        read -p "  [ ] Telegram Bot Interface? (y/N): " -n 1 -r
        echo
        [[ $REPLY =~ ^[Yy]$ ]] && INSTALL_TELEGRAM=true

        read -p "  [ ] Web Chat Interface? (y/N): " -n 1 -r
        echo
        [[ $REPLY =~ ^[Yy]$ ]] && INSTALL_WEB=true

        read -p "  [ ] Remote Server Integration? (y/N): " -n 1 -r
        echo
        [[ $REPLY =~ ^[Yy]$ ]] && INSTALL_REMOTE=true
    fi
fi

echo ""
echo "Will install:"
echo -e "  ${GREEN}✓${NC} Core (always)"
$INSTALL_TELEGRAM && echo -e "  ${GREEN}✓${NC} Telegram Bot"
$INSTALL_WEB && echo -e "  ${GREEN}✓${NC} Web Chat Interface"
$INSTALL_REMOTE && echo -e "  ${GREEN}✓${NC} Remote Server Integration"
echo ""

if [ "$NO_CONFIRM" == false ] && [ "$DRY_RUN" == false ]; then
    read -p "Continue with installation? (Y/n): " -n 1 -r
    echo
    [[ $REPLY =~ ^[Nn]$ ]] && exit 0
fi

# Create install directory
dry_run mkdir -p "$INSTALL_DIR"/{config,logs,modules}
dry_run mkdir -p "$REPOS_DIR"

# Phase 1: System packages
section "Phase 1: System Prerequisites"

if [ "$DRY_RUN" == true ]; then
    info "Would update package lists and install: git curl wget build-essential python3 python3-pip python3-venv jq unzip"
else
    log "Updating package lists..."
    sudo apt update -qq

    log "Installing essential packages..."
    sudo apt install -y -qq \
        git \
        curl \
        wget \
        build-essential \
        python3 \
        python3-pip \
        python3-venv \
        jq \
        unzip
fi

# Phase 2: Node.js (using nvm)
section "Phase 2: Node.js"

if ! command -v node &> /dev/null; then
    if [ "$DRY_RUN" == true ]; then
        info "Would install nvm and Node.js LTS"
    else
        if [ ! -d "$HOME/.nvm" ]; then
            log "Installing nvm..."
            curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
        fi

        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

        log "Installing Node.js LTS..."
        nvm install --lts
        nvm use --lts

        # Ensure nvm node is used for npm install
        NVM_NODE_PATH="$NVM_DIR/versions/node/$(nvm current)/bin"
        export PATH="$NVM_NODE_PATH:$PATH"
    fi
else
    log "Node.js $(node --version) already installed"
fi

if [ "$DRY_RUN" == false ]; then
    log "Node.js $(node --version) ready"
fi

# Phase 3: GitHub CLI
section "Phase 3: GitHub CLI"

if ! command -v gh &> /dev/null; then
    if [ "$DRY_RUN" == true ]; then
        info "Would install GitHub CLI"
    else
        log "Installing GitHub CLI..."
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null
        sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
        sudo apt update -qq
        sudo apt install -y -qq gh
    fi
fi
log "GitHub CLI ready"

# Phase 4: Claude Code
section "Phase 4: Claude Code CLI"

if ! command -v claude &> /dev/null; then
    if [ "$DRY_RUN" == true ]; then
        info "Would install Claude Code CLI via npm"
    else
        log "Installing Claude Code CLI..."
        # Source nvm to ensure we use nvm's node/npm
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        npm install -g @anthropic-ai/claude-code
    fi
fi
log "Claude Code ready"

# Phase 5: Clone ThinxAI repo
section "Phase 5: ThinxAI Repository"

THINX_REPO="$REPOS_DIR/thinxai"
if [ ! -d "$THINX_REPO" ]; then
    if [ "$DRY_RUN" == true ]; then
        info "Would clone ThinxAI repository to $THINX_REPO"
    else
        log "Cloning ThinxAI repository..."
        git clone https://github.com/jdlongmire/thinxai.net.git "$THINX_REPO" || {
            warn "Could not clone from GitHub, creating local structure..."
            mkdir -p "$THINX_REPO"/{memory,scripts,config}
        }
    fi
else
    log "ThinxAI repository exists"
fi

# Phase 6: Python Virtual Environment
section "Phase 6: Python Virtual Environment"

if [ "$DRY_RUN" == true ]; then
    info "Would create Python venv at $VENV_DIR"
else
    if [ ! -d "$VENV_DIR" ]; then
        log "Creating Python virtual environment..."
        python3 -m venv "$VENV_DIR"
    fi

    # Activate venv
    source "$VENV_DIR/bin/activate"

    # Upgrade pip
    pip install --upgrade pip -q

    log "Python venv ready at: $VENV_DIR"
fi

# Phase 7: Claude Code configuration
section "Phase 7: Claude Code Configuration"

CLAUDE_DIR="$HOME/.claude"
dry_run mkdir -p "$CLAUDE_DIR"

# Create base settings
if [ "$DRY_RUN" == true ]; then
    info "Would create Claude Code settings at $CLAUDE_DIR/settings.local.json"
else
    log "Creating Claude Code settings..."
    cat > "$CLAUDE_DIR/settings.local.json" << 'SETTINGS'
{
  "theme": "dark",
  "autoApprove": [],
  "customInstructions": "You are ThinxAI, an agentic orchestrator and local sysadmin assistant. Follow the Human-Curated, AI-Enabled (HCAE) model: assist with execution, but defer to human judgment for decisions.",
  "permissions": {
    "allow": [
      "Bash(git *)",
      "Bash(npm *)",
      "Bash(python3 *)"
    ],
    "deny": [
      "Bash(rm -rf /)",
      "Bash(sudo rm *)"
    ]
  }
}
SETTINGS
fi
log "Base configuration created"

# Phase 8: Credentials template
section "Phase 8: Credentials"

CREDS_FILE="$INSTALL_DIR/config/credentials.env"
if [ ! -f "$CREDS_FILE" ] || [ "$DRY_RUN" == true ]; then
    if [ "$DRY_RUN" == true ]; then
        info "Would create credentials template at $CREDS_FILE"
    else
        log "Creating credentials template..."
        cat > "$CREDS_FILE" << 'CREDS'
# ThinxAI Credentials
# Fill in your values and source this file

# Required: Anthropic API key for Claude
export ANTHROPIC_API_KEY=""

# Claude Model (configurable)
export THINXAI_CLAUDE_MODEL="claude-sonnet-4-20250514"

# Optional: OpenAI API key (for fallback/comparison)
export OPENAI_API_KEY=""

# Optional: Gmail for notifications
export GMAIL_ADDRESS=""
export GMAIL_APP_PASSWORD=""
export NOTIFICATION_EMAIL=""

# Telegram Bot (if using Telegram interface)
export TELEGRAM_BOT_TOKEN=""
export TELEGRAM_ALLOWED_USERS=""  # Comma-separated user IDs

# Web Interface (if using web chat)
export THINXAI_WEB_HOST="127.0.0.1"
export THINXAI_WEB_PORT="8080"

# Remote Server (if using remote integration)
export REMOTE_HOST=""
export REMOTE_USER=""
export REMOTE_SSH_KEY="~/.ssh/id_ed25519"

# Ollama (if using local LLM)
export OLLAMA_HOST=""

# ThinxAI Paths
export THINXAI_DIR="$HOME/.thinxai"
export THINXAI_VENV="$HOME/.thinxai/venv"
CREDS
        chmod 600 "$CREDS_FILE"

        # Add to bashrc
        if ! grep -q "thinxai" ~/.bashrc 2>/dev/null; then
            echo "" >> ~/.bashrc
            echo "# ThinxAI" >> ~/.bashrc
            echo "[ -f $CREDS_FILE ] && source $CREDS_FILE" >> ~/.bashrc
            echo "[ -d \$THINXAI_VENV ] && source \$THINXAI_VENV/bin/activate 2>/dev/null" >> ~/.bashrc
        fi
    fi
fi
log "Credentials template at: $CREDS_FILE"

# Interface modules - source the module scripts
MODULES_DIR="$SCRIPT_DIR/modules"

# Check if we're running from the repo or via curl
if [ ! -d "$MODULES_DIR" ]; then
    # Running via curl, download modules to temp
    MODULES_DIR=$(mktemp -d)
    if [ "$DRY_RUN" == false ]; then
        curl -fsSL "$GITHUB_RAW/modules/telegram.sh" -o "$MODULES_DIR/telegram.sh"
        curl -fsSL "$GITHUB_RAW/modules/web-chat.sh" -o "$MODULES_DIR/web-chat.sh"
        curl -fsSL "$GITHUB_RAW/modules/remote-server.sh" -o "$MODULES_DIR/remote-server.sh"
    fi
fi

if $INSTALL_TELEGRAM; then
    section "Module: Telegram Bot"

    if [ "$DRY_RUN" == true ]; then
        info "Would install Telegram bot module"
        info "  - Create telegram-bridge directory"
        info "  - Install: python-telegram-bot anthropic python-dotenv"
        info "  - Create telegram_bot.py with configurable model"
        info "  - Create systemd service template"
    else
        # Install deps in venv
        source "$VENV_DIR/bin/activate"
        pip install -q python-telegram-bot anthropic python-dotenv

        # Run module script
        source "$MODULES_DIR/telegram.sh"
    fi
fi

if $INSTALL_WEB; then
    section "Module: Web Chat Interface"

    if [ "$DRY_RUN" == true ]; then
        info "Would install Web Chat module"
        info "  - Create web-chat directory"
        info "  - Install: aiohttp anthropic python-dotenv"
        info "  - Create web_chat.py with configurable model and port"
        info "  - Create systemd service template"
    else
        # Install deps in venv
        source "$VENV_DIR/bin/activate"
        pip install -q aiohttp anthropic python-dotenv

        # Run module script
        source "$MODULES_DIR/web-chat.sh"
    fi
fi

if $INSTALL_REMOTE; then
    section "Module: Remote Server Integration"

    if [ "$DRY_RUN" == true ]; then
        info "Would install Remote Server module"
        info "  - Create remote config directory"
        info "  - Create SETUP.md documentation"
        info "  - Create test-connection.sh script"
    else
        # Run module script
        source "$MODULES_DIR/remote-server.sh"
    fi
fi

# Create templates directory
mkdir -p "$SCRIPT_DIR/templates" 2>/dev/null || true

# Phase 9: Post-install test
section "Phase 9: Verification"

run_post_install_test() {
    local passed=0
    local total=0

    echo "Running post-install checks..."
    echo ""

    # Check 1: Claude CLI
    ((total++))
    if command -v claude &> /dev/null; then
        log "Claude Code CLI: installed"
        ((passed++))
    else
        warn "Claude Code CLI: not found (may need shell reload)"
    fi

    # Check 2: Git
    ((total++))
    if command -v git &> /dev/null; then
        log "Git: installed"
        ((passed++))
    else
        warn "Git: not found"
    fi

    # Check 3: GitHub CLI
    ((total++))
    if command -v gh &> /dev/null; then
        log "GitHub CLI: installed"
        ((passed++))
    else
        warn "GitHub CLI: not found"
    fi

    # Check 4: Node.js
    ((total++))
    if command -v node &> /dev/null; then
        log "Node.js: $(node --version)"
        ((passed++))
    else
        warn "Node.js: not found (may need shell reload for nvm)"
    fi

    # Check 5: Python venv
    ((total++))
    if [ -f "$VENV_DIR/bin/activate" ]; then
        log "Python venv: $VENV_DIR"
        ((passed++))
    else
        warn "Python venv: not created"
    fi

    # Check 6: Credentials file
    ((total++))
    if [ -f "$CREDS_FILE" ]; then
        log "Credentials file: exists"
        ((passed++))
    else
        warn "Credentials file: not found"
    fi

    # Check 7: Claude config
    ((total++))
    if [ -f "$CLAUDE_DIR/settings.local.json" ]; then
        log "Claude config: exists"
        ((passed++))
    else
        warn "Claude config: not found"
    fi

    # Optional checks based on what was installed
    if $INSTALL_TELEGRAM; then
        ((total++))
        if [ -f "$THINX_REPO/telegram-bridge/telegram_bot.py" ]; then
            log "Telegram bot: installed"
            ((passed++))
        else
            warn "Telegram bot: script not found"
        fi
    fi

    if $INSTALL_WEB; then
        ((total++))
        if [ -f "$THINX_REPO/web-chat/web_chat.py" ]; then
            log "Web chat: installed"
            ((passed++))
        else
            warn "Web chat: script not found"
        fi
    fi

    echo ""
    echo "Verification: $passed/$total checks passed"

    if [ $passed -eq $total ]; then
        return 0
    else
        return 1
    fi
}

if [ "$DRY_RUN" == true ]; then
    info "Would run post-install verification"
else
    run_post_install_test || warn "Some checks failed - see above"
fi

# Final summary
section "Installation Complete!"

echo ""
echo "ThinxAI has been installed to: $INSTALL_DIR"
echo ""
echo -e "${BOLD}Next Steps:${NC}"
echo ""
echo "1. Edit credentials:"
echo "   nano $CREDS_FILE"
echo "   - Add your ANTHROPIC_API_KEY"
$INSTALL_TELEGRAM && echo "   - Add TELEGRAM_BOT_TOKEN"
echo ""
echo "2. Reload shell:"
echo "   source ~/.bashrc"
echo ""
echo "3. Authenticate GitHub (if not already):"
echo "   gh auth login"
echo ""
echo "4. Launch Claude Code:"
echo "   cd $THINX_REPO && claude"
echo ""
if $INSTALL_WEB; then
    echo "5. Start Web Chat (optional):"
    echo "   source $VENV_DIR/bin/activate"
    echo "   python3 $THINX_REPO/web-chat/web_chat.py"
    echo ""
fi
if $INSTALL_TELEGRAM; then
    echo "5. Start Telegram Bot (optional):"
    echo "   source $VENV_DIR/bin/activate"
    echo "   python3 $THINX_REPO/telegram-bridge/telegram_bot.py"
    echo ""
fi
echo -e "${BOLD}Documentation:${NC} https://thinxai.net/docs"
echo -e "${BOLD}Support:${NC} https://github.com/jdlongmire/thinxai.net/issues"
echo ""
echo -e "${GREEN}Welcome to ThinxAI!${NC}"
echo ""
