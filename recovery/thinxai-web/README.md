# ThinxAI Web Chat (Standalone)

A lightweight web interface for Claude CLI - no Telegram dependency.

## Quick Start

```bash
cd thinxai-web
python web_chat.py --port 8080
```

Then open http://localhost:8080

## Features

- **Chat interface** - Clean web UI for chatting with Claude
- **Streaming responses** - Real-time SSE streaming with tool status
- **File uploads** - Drag-and-drop or click to upload (20MB limit)
- **Image display** - Automatic image rendering with fullscreen modal
- **Conversation history** - Persisted in JSONL format
- **MEMORY.md context** - Loads shared memory file for context

## Configuration

Environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `THINX_MEMORY` | `../MEMORY.md` | Path to MEMORY.md context file |
| `THINX_HISTORY` | `./history` | Directory for conversation history |
| `THINX_DOWNLOADS` | `./downloads` | Directory for uploaded files |

## Command Line

```bash
python web_chat.py [--host HOST] [--port PORT]
```

- `--host` - Host to bind to (default: `0.0.0.0`)
- `--port` - Port to listen on (default: `8080`)

## Running as a Service

Create `/etc/systemd/system/thinxai-web.service`:

```ini
[Unit]
Description=ThinxAI Web Chat
After=network.target

[Service]
Type=simple
User=your-user
WorkingDirectory=/path/to/thinxai-web
ExecStart=/usr/bin/python3 web_chat.py --port 8080
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

Then:
```bash
sudo systemctl daemon-reload
sudo systemctl enable thinxai-web
sudo systemctl start thinxai-web
```

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | Web interface |
| `/api/status` | GET | Health check |
| `/api/history` | GET | Get conversation history |
| `/api/message/stream` | POST | Send message (SSE streaming) |
| `/api/upload` | POST | Upload file |
| `/api/image` | GET | Serve image file |

## Requirements

- Python 3.8+
- aiohttp
- Claude CLI installed and configured

Install dependencies:
```bash
pip install aiohttp
```

## Differences from Telegram Bridge

This standalone version:
- **No Telegram bot** - Just web interface
- **No cross-channel sync** - Single user, single session
- **Simpler deployment** - No bot token needed
- **Portable** - Can run on any machine with Claude CLI
