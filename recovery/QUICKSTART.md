# ThinxAI Telegram Bridge - Quick Reference

## Quick Recovery (if you have credentials saved)

```bash
cd /path/to/thinx
./thinx-recovery/setup.sh
cp /path/to/saved/.env thinxai-telegram/.env
cd thinxai-telegram && nohup python3 bridge.py > /tmp/bridge.log 2>&1 &
```

## Credentials You Need

| Credential | Where to Get It |
|------------|-----------------|
| Telegram Bot Token | @BotFather on Telegram → `/token` |
| Your Telegram User ID | @userinfobot on Telegram |
| Gmail App Password | Google Account → Security → 2FA → App Passwords |

## Common Commands

### Start Bridge
```bash
cd thinxai-telegram
nohup python3 bridge.py > /tmp/bridge.log 2>&1 &
```

### Stop Bridge
```bash
pkill -f "python3 bridge.py"
```

### Restart Bridge
```bash
pkill -f "python3 bridge.py"; sleep 1
cd thinxai-telegram && nohup python3 bridge.py > /tmp/bridge.log 2>&1 &
```

### Check Status
```bash
ps aux | grep bridge.py | grep -v grep
```

### View Logs
```bash
tail -f /tmp/bridge.log
```

### Test Import (check for errors)
```bash
cd thinxai-telegram && python3 -c "import bridge"
```

## Telegram Bot Commands

| Command | Description |
|---------|-------------|
| `/start` | Show help |
| `/clear` | Reset conversation |
| `/context` | Show memory status |
| `/sudo <request>` | Execute without confirmation |

## Natural Language Examples

- "Check my email"
- "What's in my inbox?"
- "Send me a test email"
- "Send an email to john@example.com about the meeting"
- "Show me the image at /path/to/photo.png"
- "Display that avatar image"
- "List files in the oddxian repo"
- "What's the git status?"

## File Locations

| File | Purpose |
|------|---------|
| `thinxai-telegram/.env` | Credentials (gitignored) |
| `.claude/settings.local.json` | Permissions (gitignored) |
| `memory/telegram/*.jsonl` | Chat history (gitignored) |
| `MEMORY.md` | Shared context |
| `/tmp/bridge.log` | Runtime logs |
