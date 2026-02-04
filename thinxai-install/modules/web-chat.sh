#!/bin/bash
# ThinxAI Web Chat Module
# Browser-based interface to your ThinxAI agent

set -e

INSTALL_DIR="${THINXAI_DIR:-$HOME/.thinxai}"
WEB_DIR="${THINXAI_REPO:-$HOME/GitHub_Repos/thinxai}/web-chat"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
info() { echo -e "${CYAN}[i]${NC} $1"; }

echo ""
echo "═══ Web Chat Module ═══"
echo ""

# Create directory structure
mkdir -p "$WEB_DIR"/{web,profiles,history}

# Install dependencies
log "Installing Python dependencies..."
pip3 install -q aiohttp anthropic python-dotenv 2>/dev/null || {
    warn "Auto-install failed. Run manually:"
    echo "  pip3 install aiohttp anthropic python-dotenv"
}

# Create web server
if [ ! -f "$WEB_DIR/web_chat.py" ]; then
    log "Creating web server..."
    cat > "$WEB_DIR/web_chat.py" << 'WEBPY'
#!/usr/bin/env python3
"""
ThinxAI Web Chat Server
Browser-based access to your local AI assistant
"""

import os
import json
import asyncio
import argparse
from datetime import datetime
from pathlib import Path
from aiohttp import web
from dotenv import load_dotenv
import anthropic

load_dotenv()

# Configuration
ANTHROPIC_KEY = os.getenv("ANTHROPIC_API_KEY")
HOST = os.getenv("THINXAI_WEB_HOST", "127.0.0.1")
PORT = int(os.getenv("THINXAI_WEB_PORT", "8080"))

# Paths
SCRIPT_DIR = Path(__file__).parent
WEB_DIR = SCRIPT_DIR / "web"
HISTORY_DIR = SCRIPT_DIR / "history"
HISTORY_DIR.mkdir(exist_ok=True)

# Claude client
client = anthropic.Anthropic(api_key=ANTHROPIC_KEY)

# Session storage
sessions = {}

async def index(request):
    """Serve the main page"""
    html_path = WEB_DIR / "index.html"
    if html_path.exists():
        return web.FileResponse(html_path)
    return web.Response(text=DEFAULT_HTML, content_type="text/html")

async def chat(request):
    """Handle chat messages"""
    try:
        data = await request.json()
        message = data.get("message", "")
        session_id = data.get("session_id", "default")

        # Get or create session history
        if session_id not in sessions:
            sessions[session_id] = []

        # Add user message to history
        sessions[session_id].append({"role": "user", "content": message})

        # Keep last 20 messages for context
        context_messages = sessions[session_id][-20:]

        # Get response from Claude
        response = client.messages.create(
            model=os.getenv("THINXAI_CLAUDE_MODEL", "claude-sonnet-4-20250514"),
            max_tokens=2048,
            system="You are ThinxAI, a helpful local AI assistant. Be concise but thorough.",
            messages=context_messages
        )

        assistant_message = response.content[0].text

        # Add to history
        sessions[session_id].append({"role": "assistant", "content": assistant_message})

        # Log to file
        log_entry = {
            "timestamp": datetime.now().isoformat(),
            "session": session_id,
            "user": message,
            "assistant": assistant_message
        }
        with open(HISTORY_DIR / f"{session_id}.jsonl", "a") as f:
            f.write(json.dumps(log_entry) + "\n")

        return web.json_response({
            "response": assistant_message,
            "session_id": session_id
        })

    except Exception as e:
        return web.json_response({"error": str(e)}, status=500)

async def health(request):
    """Health check endpoint"""
    return web.json_response({
        "status": "ok",
        "timestamp": datetime.now().isoformat(),
        "sessions": len(sessions)
    })

# Default HTML if index.html doesn't exist
DEFAULT_HTML = """<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ThinxAI Chat</title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: #1a1a2e;
            color: #eee;
            height: 100vh;
            display: flex;
            flex-direction: column;
        }
        header {
            background: #16213e;
            padding: 1rem;
            text-align: center;
            border-bottom: 1px solid #0f3460;
        }
        header h1 { font-size: 1.5rem; color: #00d9ff; }
        #chat {
            flex: 1;
            overflow-y: auto;
            padding: 1rem;
            display: flex;
            flex-direction: column;
            gap: 1rem;
        }
        .message {
            max-width: 80%;
            padding: 0.75rem 1rem;
            border-radius: 1rem;
            line-height: 1.5;
        }
        .user {
            align-self: flex-end;
            background: #0f3460;
        }
        .assistant {
            align-self: flex-start;
            background: #1a1a2e;
            border: 1px solid #0f3460;
        }
        #input-area {
            padding: 1rem;
            background: #16213e;
            display: flex;
            gap: 0.5rem;
        }
        #message-input {
            flex: 1;
            padding: 0.75rem 1rem;
            border: 1px solid #0f3460;
            border-radius: 1.5rem;
            background: #1a1a2e;
            color: #eee;
            font-size: 1rem;
        }
        #message-input:focus { outline: none; border-color: #00d9ff; }
        #send-btn {
            padding: 0.75rem 1.5rem;
            background: #00d9ff;
            color: #1a1a2e;
            border: none;
            border-radius: 1.5rem;
            font-weight: bold;
            cursor: pointer;
        }
        #send-btn:hover { background: #00b8d4; }
        #send-btn:disabled { background: #444; cursor: not-allowed; }
    </style>
</head>
<body>
    <header>
        <h1>ThinxAI</h1>
    </header>
    <div id="chat"></div>
    <div id="input-area">
        <input type="text" id="message-input" placeholder="Type a message..." autofocus>
        <button id="send-btn">Send</button>
    </div>
    <script>
        const chat = document.getElementById('chat');
        const input = document.getElementById('message-input');
        const btn = document.getElementById('send-btn');
        const sessionId = 'session_' + Date.now();

        function addMessage(text, role) {
            const div = document.createElement('div');
            div.className = 'message ' + role;
            div.textContent = text;
            chat.appendChild(div);
            chat.scrollTop = chat.scrollHeight;
        }

        async function send() {
            const message = input.value.trim();
            if (!message) return;

            addMessage(message, 'user');
            input.value = '';
            btn.disabled = true;

            try {
                const res = await fetch('/chat', {
                    method: 'POST',
                    headers: {'Content-Type': 'application/json'},
                    body: JSON.stringify({message, session_id: sessionId})
                });
                const data = await res.json();
                if (data.error) throw new Error(data.error);
                addMessage(data.response, 'assistant');
            } catch (e) {
                addMessage('Error: ' + e.message, 'assistant');
            }
            btn.disabled = false;
            input.focus();
        }

        btn.onclick = send;
        input.onkeypress = e => { if (e.key === 'Enter') send(); };
    </script>
</body>
</html>
"""

def main():
    parser = argparse.ArgumentParser(description="ThinxAI Web Chat Server")
    parser.add_argument("--host", default=HOST, help="Host to bind to")
    parser.add_argument("--port", type=int, default=PORT, help="Port to listen on")
    args = parser.parse_args()

    if not ANTHROPIC_KEY:
        print("Error: ANTHROPIC_API_KEY not set")
        return

    app = web.Application()
    app.router.add_get("/", index)
    app.router.add_post("/chat", chat)
    app.router.add_get("/health", health)
    app.router.add_static("/static", WEB_DIR, show_index=False)

    print(f"Starting ThinxAI Web Chat on http://{args.host}:{args.port}")
    web.run_app(app, host=args.host, port=args.port, print=None)

if __name__ == "__main__":
    main()
WEBPY
    chmod +x "$WEB_DIR/web_chat.py"
fi

# Create systemd service template
log "Creating systemd service template..."
cat > "$INSTALL_DIR/config/thinxai-web.service" << WEBSERVICE
[Unit]
Description=ThinxAI Web Chat
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$WEB_DIR
EnvironmentFile=$INSTALL_DIR/config/credentials.env
ExecStart=/usr/bin/python3 web_chat.py --port 8080
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
WEBSERVICE

log "Web Chat module installed"
echo ""
info "Start manually: python3 $WEB_DIR/web_chat.py"
info "Access at: http://localhost:8080"
echo ""
info "For remote access via Tailscale:"
echo "  tailscale funnel 8080"
echo ""
info "Or as service:"
echo "  sudo cp $INSTALL_DIR/config/thinxai-web.service /etc/systemd/system/"
echo "  sudo systemctl daemon-reload"
echo "  sudo systemctl enable --now thinxai-web"
echo ""
