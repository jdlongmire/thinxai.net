#!/bin/bash
# ThinxAI Complete Recovery Script
# Run on fresh Ubuntu machine with Claude Code base installation
# Usage: bash setup.sh
#
# Prerequisites:
# - Ubuntu 22.04+
# - Internet connection
# - This USB drive mounted

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=============================================="
echo "  ThinxAI Complete Recovery"
echo "=============================================="
echo ""
echo "Recovery folder: $SCRIPT_DIR"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; exit 1; }
section() { echo -e "\n${CYAN}=== $1 ===${NC}"; }

# Check not root
if [ "$EUID" -eq 0 ]; then
    error "Do not run as root. Run as your normal user."
fi

# ============================================
section "Phase 1: System Prerequisites"
# ============================================

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
    ffmpeg \
    jq \
    msmtp \
    msmtp-mta \
    unzip

# ============================================
section "Phase 2: Node.js (via nvm)"
# ============================================

if ! command -v nvm &> /dev/null && [ ! -d "$HOME/.nvm" ]; then
    log "Installing nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
fi

# Load nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

log "Installing Node.js LTS..."
nvm install --lts
nvm use --lts
log "Node.js $(node --version) installed"

# ============================================
section "Phase 3: GitHub CLI"
# ============================================

if ! command -v gh &> /dev/null; then
    log "Installing GitHub CLI..."
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt update -qq
    sudo apt install -y -qq gh
else
    log "GitHub CLI already installed"
fi

# ============================================
section "Phase 4: Claude Code CLI"
# ============================================

if ! command -v claude &> /dev/null; then
    log "Installing Claude Code CLI..."
    npm install -g @anthropic-ai/claude-code
else
    log "Claude Code CLI already installed ($(claude --version 2>/dev/null | head -1))"
fi

# ============================================
section "Phase 5: VS Code"
# ============================================

if ! command -v code &> /dev/null; then
    log "Installing VS Code..."
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
    echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
    rm -f packages.microsoft.gpg
    sudo apt update -qq
    sudo apt install -y -qq code
else
    log "VS Code already installed"
fi

log "Installing VS Code extensions..."
code --install-extension anthropics.claude-code 2>/dev/null || warn "Install manually: anthropics.claude-code"

# ============================================
section "Phase 6: Clone Repositories"
# ============================================

REPOS_DIR="$HOME/GitHub_Repos"
mkdir -p "$REPOS_DIR"

clone_repo() {
    local repo=$1
    local dir=$2
    if [ ! -d "$dir" ]; then
        log "Cloning $repo..."
        gh repo clone "$repo" "$dir" 2>/dev/null || git clone "https://github.com/$repo.git" "$dir"
    else
        log "$repo already exists"
    fi
}

# Primary repos
clone_repo "jdlongmire/thinx" "$REPOS_DIR/thinx"
clone_repo "jdlongmire/thinx-dashboard" "$REPOS_DIR/thinx-dashboard"
clone_repo "jdlongmire/AI-Research" "$REPOS_DIR/AI-Research"
clone_repo "jdlongmire/oddxian-apologetics" "$REPOS_DIR/oddxian-apologetics"
clone_repo "jdlongmire/logic-realism-theory" "$REPOS_DIR/logic-realism-theory"
clone_repo "jdlongmire/thinxai.net" "$REPOS_DIR/thinxai.net"

# ============================================
section "Phase 7: Claude Code Configuration"
# ============================================

CLAUDE_DIR="$HOME/.claude"
mkdir -p "$CLAUDE_DIR/skills"

log "Installing Claude Code settings..."
cp "$SCRIPT_DIR/config/settings.local.json" "$CLAUDE_DIR/settings.local.json"

log "Installing custom skills..."
cp "$SCRIPT_DIR/config/skills/"*.md "$CLAUDE_DIR/skills/" 2>/dev/null || true

log "Installing diagram commands (repo-level skills)..."
THINX_CLAUDE_DIR="$REPOS_DIR/thinx/.claude"
mkdir -p "$THINX_CLAUDE_DIR/commands" "$THINX_CLAUDE_DIR/hooks"
cp "$SCRIPT_DIR/config/commands/"*.md "$THINX_CLAUDE_DIR/commands/" 2>/dev/null || true
cp "$SCRIPT_DIR/config/settings.json" "$THINX_CLAUDE_DIR/" 2>/dev/null || true

log "Setting up project hooks..."
cp "$SCRIPT_DIR/config/hooks/"*.sh "$THINX_CLAUDE_DIR/hooks/" 2>/dev/null || true
chmod +x "$THINX_CLAUDE_DIR/hooks/"*.sh 2>/dev/null || true

# ============================================
section "Phase 8: Cron Jobs"
# ============================================

log "Installing cron jobs..."
THINX_DIR="$REPOS_DIR/thinx"

# Build crontab
CRON_TEMP=$(mktemp)
cat > "$CRON_TEMP" << EOF
# ThinxAI Dashboard auto-update - hourly
0 * * * * $THINX_DIR/scripts/update-dashboard.sh >> /tmp/dashboard-update.log 2>&1
# ThinxAI Health email - hourly
30 * * * * $THINX_DIR/scripts/health-email.sh >> /tmp/health-email.log 2>&1
# Meta-context daily rotation - midnight
0 0 * * * $THINX_DIR/scripts/rotate-meta-context.sh >> /tmp/meta-context-rotate.log 2>&1
# Meta-context quarterly rollup - 1st of Jan, Apr, Jul, Oct at 1am
0 1 1 1,4,7,10 * $THINX_DIR/scripts/rotate-meta-context.sh --quarterly >> /tmp/meta-context-rotate.log 2>&1
# ThinxAI daily backup - 2am
0 2 * * * $THINX_DIR/scripts/backup.sh >> /tmp/backup.log 2>&1
EOF

crontab "$CRON_TEMP"
rm "$CRON_TEMP"
log "Cron jobs installed"

# ============================================
section "Phase 9: Telegram Bridge"
# ============================================

BRIDGE_DIR="$THINX_DIR/thinxai-telegram"
if [ -d "$BRIDGE_DIR" ]; then
    log "Installing Telegram bridge dependencies..."
    cd "$BRIDGE_DIR"
    pip3 install -q python-telegram-bot anthropic python-dotenv 2>/dev/null || true
    cd - > /dev/null
fi

# ============================================
section "Phase 9b: Web Chat Interface"
# ============================================

WEB_CHAT_DIR="$THINX_DIR/thinxai-web"
log "Setting up ThinxAI Web Chat..."

# Install web chat dependencies
pip3 install -q aiohttp 2>/dev/null || warn "Install manually: pip3 install aiohttp"

# Copy web chat from recovery if not in cloned repo
if [ ! -f "$WEB_CHAT_DIR/web_chat.py" ]; then
    log "Copying web chat from recovery package..."
    mkdir -p "$WEB_CHAT_DIR/web" "$WEB_CHAT_DIR/profiles"
    cp "$SCRIPT_DIR/thinxai-web/web_chat.py" "$WEB_CHAT_DIR/"
    cp "$SCRIPT_DIR/thinxai-web/email_utils.py" "$WEB_CHAT_DIR/" 2>/dev/null || true
    cp "$SCRIPT_DIR/thinxai-web/web/"* "$WEB_CHAT_DIR/web/" 2>/dev/null || true
    cp "$SCRIPT_DIR/thinxai-web/profiles/"*.md "$WEB_CHAT_DIR/profiles/" 2>/dev/null || true
    cp "$SCRIPT_DIR/thinxai-web/README.md" "$WEB_CHAT_DIR/" 2>/dev/null || true
else
    log "Web chat already exists in repo"
fi

# Create systemd service (optional)
log "Creating web chat systemd service template..."
cat > /tmp/thinxai-web.service << SVCEOF
[Unit]
Description=ThinxAI Web Chat
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$WEB_CHAT_DIR
Environment="THINX_MEMORY=$THINX_DIR/MEMORY.md"
ExecStart=/usr/bin/python3 web_chat.py --port 8080
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
SVCEOF

log "Web chat service template created at /tmp/thinxai-web.service"
log "To enable: sudo cp /tmp/thinxai-web.service /etc/systemd/system/ && sudo systemctl enable thinxai-web"

# ============================================
section "Phase 10: Git Configuration"
# ============================================

if ! git config --global user.email &> /dev/null; then
    warn "Git user not configured"
    echo ""
    echo "Run:"
    echo "  git config --global user.name 'JD Longmire'"
    echo "  git config --global user.email 'longmire.jd@gmail.com'"
else
    log "Git user configured: $(git config --global user.name) <$(git config --global user.email)>"
fi

# ============================================
section "Phase 11: Credential Setup"
# ============================================

CREDS_FILE="$HOME/.thinxai-credentials"
if [ ! -f "$CREDS_FILE" ]; then
    log "Creating credentials template..."
    cp "$SCRIPT_DIR/config/credentials-template.env" "$CREDS_FILE"

    # Add to bashrc if not already
    if ! grep -q "thinxai-credentials" ~/.bashrc 2>/dev/null; then
        echo "" >> ~/.bashrc
        echo "# ThinxAI credentials" >> ~/.bashrc
        echo "source ~/.thinxai-credentials" >> ~/.bashrc
    fi
else
    log "Credentials file already exists"
fi

# ============================================
echo ""
echo "=============================================="
echo "  Setup Complete!"
echo "=============================================="
echo ""
echo "MANUAL STEPS REQUIRED:"
echo ""
echo "1. Edit credentials:"
echo "   nano ~/.thinxai-credentials"
echo "   - Add ANTHROPIC_API_KEY"
echo "   - Add OPENAI_API_KEY"
echo "   - Add TELEGRAM_BOT_TOKEN (create via @BotFather)"
echo "   - Add GMAIL credentials for health emails"
echo ""
echo "2. Reload shell:"
echo "   source ~/.bashrc"
echo ""
echo "3. Authenticate GitHub:"
echo "   gh auth login"
echo ""
echo "4. Run Claude Code to authenticate:"
echo "   cd ~/GitHub_Repos/thinx && claude"
echo ""
echo "5. Create Telegram .env:"
echo "   cp ~/.thinxai-credentials ~/GitHub_Repos/thinx/thinxai-telegram/.env"
echo "   (edit to match expected format)"
echo ""
echo "6. Start Web Chat (optional):"
echo "   cd ~/GitHub_Repos/thinx/thinxai-web && python3 web_chat.py"
echo "   Or enable as service:"
echo "   sudo cp /tmp/thinxai-web.service /etc/systemd/system/"
echo "   sudo systemctl daemon-reload && sudo systemctl enable --now thinxai-web"
echo ""
echo "=============================================="
