#!/bin/bash
# ThinxAI Telegram Bot Module
# Provides mobile access to your ThinxAI agent

set -e

INSTALL_DIR="${THINXAI_DIR:-$HOME/.thinxai}"
TELEGRAM_DIR="${THINXAI_REPO:-$HOME/GitHub_Repos/thinxai}/telegram-bridge"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
info() { echo -e "${CYAN}[i]${NC} $1"; }

echo ""
echo "═══ Telegram Bot Module ═══"
echo ""

# Create directory structure
mkdir -p "$TELEGRAM_DIR"

# Install dependencies
log "Installing Python dependencies..."
pip3 install -q python-telegram-bot anthropic python-dotenv 2>/dev/null || {
    warn "Auto-install failed. Run manually:"
    echo "  pip3 install python-telegram-bot anthropic python-dotenv"
}

# Create bot template
if [ ! -f "$TELEGRAM_DIR/telegram_bot.py" ]; then
    log "Creating bot template..."
    cat > "$TELEGRAM_DIR/telegram_bot.py" << 'BOTPY'
#!/usr/bin/env python3
"""
ThinxAI Telegram Bot
Mobile access to your local AI assistant
"""

import os
import asyncio
import logging
from dotenv import load_dotenv
from telegram import Update
from telegram.ext import Application, CommandHandler, MessageHandler, filters, ContextTypes
import anthropic

load_dotenv()

# Configuration
BOT_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN")
ALLOWED_USERS = [int(x) for x in os.getenv("TELEGRAM_ALLOWED_USERS", "").split(",") if x]
ANTHROPIC_KEY = os.getenv("ANTHROPIC_API_KEY")

# Logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Claude client
client = anthropic.Anthropic(api_key=ANTHROPIC_KEY)

def is_allowed(user_id: int) -> bool:
    """Check if user is allowed to use the bot"""
    if not ALLOWED_USERS:
        return True  # No restrictions if list is empty
    return user_id in ALLOWED_USERS

async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handle /start command"""
    if not is_allowed(update.effective_user.id):
        await update.message.reply_text("Access denied.")
        return

    await update.message.reply_text(
        "Welcome to ThinxAI!\n\n"
        "I'm your local AI assistant. Send me a message and I'll help.\n\n"
        "Commands:\n"
        "/start - This message\n"
        "/status - System status\n"
        "/help - Get help"
    )

async def status(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handle /status command"""
    if not is_allowed(update.effective_user.id):
        return

    import subprocess
    try:
        uptime = subprocess.check_output(["uptime", "-p"]).decode().strip()
        await update.message.reply_text(f"System: {uptime}\nBot: Running")
    except Exception as e:
        await update.message.reply_text(f"Status check failed: {e}")

async def handle_message(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handle regular messages"""
    if not is_allowed(update.effective_user.id):
        logger.warning(f"Unauthorized access attempt from user {update.effective_user.id}")
        return

    user_message = update.message.text

    try:
        # Send typing indicator
        await update.message.chat.send_action("typing")

        # Get response from Claude
        response = client.messages.create(
            model=os.getenv("THINXAI_CLAUDE_MODEL", "claude-sonnet-4-20250514"),
            max_tokens=1024,
            system="You are ThinxAI, a helpful local AI assistant accessed via Telegram. Keep responses concise for mobile reading.",
            messages=[{"role": "user", "content": user_message}]
        )

        reply = response.content[0].text

        # Split long messages (Telegram limit is 4096 chars)
        if len(reply) > 4000:
            for i in range(0, len(reply), 4000):
                await update.message.reply_text(reply[i:i+4000])
        else:
            await update.message.reply_text(reply)

    except Exception as e:
        logger.error(f"Error processing message: {e}")
        await update.message.reply_text(f"Error: {str(e)[:200]}")

def main():
    """Start the bot"""
    if not BOT_TOKEN:
        print("Error: TELEGRAM_BOT_TOKEN not set")
        return

    if not ANTHROPIC_KEY:
        print("Error: ANTHROPIC_API_KEY not set")
        return

    app = Application.builder().token(BOT_TOKEN).build()

    app.add_handler(CommandHandler("start", start))
    app.add_handler(CommandHandler("status", status))
    app.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_message))

    logger.info("Starting ThinxAI Telegram bot...")
    app.run_polling()

if __name__ == "__main__":
    main()
BOTPY
    chmod +x "$TELEGRAM_DIR/telegram_bot.py"
fi

# Create systemd service template
log "Creating systemd service template..."
cat > "$INSTALL_DIR/config/thinxai-telegram.service" << TELESERVICE
[Unit]
Description=ThinxAI Telegram Bot
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$TELEGRAM_DIR
EnvironmentFile=$INSTALL_DIR/config/credentials.env
ExecStart=/usr/bin/python3 telegram_bot.py
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
TELESERVICE

log "Telegram module installed"
echo ""
info "Configuration required:"
echo "  1. Create a bot via @BotFather on Telegram"
echo "  2. Add TELEGRAM_BOT_TOKEN to credentials.env"
echo "  3. Add your Telegram user ID to TELEGRAM_ALLOWED_USERS"
echo ""
info "Start manually: python3 $TELEGRAM_DIR/telegram_bot.py"
info "Or as service: sudo cp $INSTALL_DIR/config/thinxai-telegram.service /etc/systemd/system/"
echo ""
