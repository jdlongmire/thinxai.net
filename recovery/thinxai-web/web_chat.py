#!/usr/bin/env python3
"""
ThinxAI Web Chat - Standalone web interface for Claude CLI

A lightweight web server that provides a chat interface to Claude Code
without any Telegram dependencies.

Usage:
    python web_chat.py [--port 8080] [--host 0.0.0.0]

Environment variables:
    THINX_MEMORY - Path to MEMORY.md (default: ../MEMORY.md)
    THINX_HISTORY - Path to conversation history dir (default: ./history)
    THINX_DOWNLOADS - Path to file uploads dir (default: ./downloads)
"""

import asyncio
import json
import logging
import os
import re
import sys
from datetime import datetime
from pathlib import Path
from aiohttp import web

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Configuration from environment or defaults
SCRIPT_DIR = Path(__file__).parent.resolve()
MEMORY_PATH = os.environ.get('THINX_MEMORY', str(SCRIPT_DIR.parent / 'MEMORY.md'))
HISTORY_DIR = Path(os.environ.get('THINX_HISTORY', str(SCRIPT_DIR / 'history')))
DOWNLOADS_DIR = Path(os.environ.get('THINX_DOWNLOADS', str(SCRIPT_DIR / 'downloads')))
WEB_DIR = SCRIPT_DIR / 'web'

# Ensure directories exist
HISTORY_DIR.mkdir(parents=True, exist_ok=True)
DOWNLOADS_DIR.mkdir(parents=True, exist_ok=True)
WEB_DIR.mkdir(parents=True, exist_ok=True)

# Default user ID for web sessions
WEB_USER_ID = "web_user"


def get_history_path(user_id: str) -> Path:
    """Get the conversation history file path for a user."""
    return HISTORY_DIR / f"{user_id}.jsonl"


def load_history(user_id: str, limit: int = 50) -> list:
    """Load recent conversation history."""
    history_path = get_history_path(user_id)
    if not history_path.exists():
        return []

    messages = []
    try:
        with open(history_path, 'r') as f:
            for line in f:
                if line.strip():
                    messages.append(json.loads(line))
        return messages[-limit:]
    except Exception as e:
        logger.error(f"Error loading history: {e}")
        return []


def save_message(user_id: str, role: str, content: str):
    """Save a message to conversation history."""
    history_path = get_history_path(user_id)
    entry = {
        "role": role,
        "content": content,
        "timestamp": datetime.now().isoformat(),
        "source": "web"
    }
    try:
        with open(history_path, 'a') as f:
            f.write(json.dumps(entry) + '\n')
    except Exception as e:
        logger.error(f"Error saving message: {e}")


def build_prompt(user_id: str, message: str) -> str:
    """Build the full prompt with context."""
    # Load recent history for context
    history = load_history(user_id, limit=20)

    parts = []

    # Add system instructions for image display
    system_instructions = """<system_instructions>
When you create or reference an image file, output it using this format so it displays in the chat:
[ACTION:show_image|/full/path/to/image.png]

For example, after generating a diagram at /tmp/diagram.png, include:
[ACTION:show_image|/tmp/diagram.png]

The image will be rendered inline in the chat interface.
</system_instructions>"""
    parts.append(system_instructions)

    # Add MEMORY.md context if available
    if os.path.exists(MEMORY_PATH):
        try:
            with open(MEMORY_PATH, 'r') as f:
                memory_content = f.read()
            parts.append(f"<memory>\n{memory_content}\n</memory>")
        except Exception as e:
            logger.warning(f"Could not read MEMORY.md: {e}")

    # Add conversation history
    if history:
        history_text = "\n".join([
            f"{msg['role']}: {msg['content']}"
            for msg in history[-10:]  # Last 10 messages
        ])
        parts.append(f"<conversation_history>\n{history_text}\n</conversation_history>")

    # Add current message
    parts.append(f"User message: {message}")

    return "\n\n".join(parts)


async def call_claude_streaming(prompt: str, skip_permissions: bool = True, on_event=None):
    """Call Claude CLI with streaming output."""
    cmd = [
        'claude',
        '--output-format', 'stream-json',
        '--verbose',
        '-p', prompt
    ]
    if skip_permissions:
        cmd.append('--dangerously-skip-permissions')

    # Use larger buffer limit (10MB) to handle large streaming events
    process = await asyncio.create_subprocess_exec(
        *cmd,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE,
        limit=10 * 1024 * 1024  # 10MB buffer limit
    )

    result_text = ""
    buffer = b""

    try:
        while True:
            # Read chunks instead of lines to handle large outputs
            chunk = await process.stdout.read(64 * 1024)  # 64KB chunks
            if not chunk:
                break

            buffer += chunk

            # Process complete lines from buffer
            while b'\n' in buffer:
                line, buffer = buffer.split(b'\n', 1)
                if not line.strip():
                    continue

                try:
                    event = json.loads(line.decode().strip())

                    # Extract text from content_block_delta events
                    if event.get("type") == "content_block_delta":
                        delta = event.get("delta", {})
                        if delta.get("type") == "text_delta":
                            result_text += delta.get("text", "")

                    # Also check for result in final message
                    if event.get("type") == "result":
                        result = event.get("result", "")
                        if result and not result_text:
                            result_text = result

                    # Forward event to callback
                    if on_event:
                        await on_event(event)

                except json.JSONDecodeError:
                    continue

        # Process any remaining buffer content
        if buffer.strip():
            try:
                event = json.loads(buffer.decode().strip())
                if event.get("type") == "result":
                    result = event.get("result", "")
                    if result and not result_text:
                        result_text = result
                if on_event:
                    await on_event(event)
            except json.JSONDecodeError:
                pass

    except Exception as e:
        logger.error(f"Streaming error: {e}")

    await process.wait()
    stderr = await process.stderr.read()

    return result_text, process.returncode, stderr.decode() if stderr else ""


# =============================================================================
# HTTP Handlers
# =============================================================================

async def handle_index(request):
    """Serve the main web interface."""
    index_path = WEB_DIR / 'index.html'
    if index_path.exists():
        return web.FileResponse(index_path)
    else:
        return web.Response(
            text="Web interface not found. Run setup first.",
            status=404
        )


async def handle_status(request):
    """Health check endpoint."""
    return web.json_response({
        "status": "ok",
        "service": "ThinxAI Web Chat",
        "timestamp": datetime.now().isoformat()
    })


async def handle_history(request):
    """Return conversation history."""
    history = load_history(WEB_USER_ID, limit=100)
    return web.json_response(history)


async def handle_message_stream(request):
    """Handle streaming message endpoint."""
    response = web.StreamResponse(
        status=200,
        reason='OK',
        headers={
            'Content-Type': 'text/event-stream',
            'Cache-Control': 'no-cache',
            'Connection': 'keep-alive',
            'Access-Control-Allow-Origin': '*',
            'X-Accel-Buffering': 'no',  # Disable nginx buffering
        }
    )
    await response.prepare(request)

    MAX_SSE_EVENT_SIZE = 16 * 1024  # 16KB per SSE event
    keep_alive_active = [True]  # Use list for mutable reference
    last_event_time = [asyncio.get_event_loop().time()]

    async def keep_alive_task():
        """Send periodic keep-alive pings to prevent mobile browser timeouts."""
        while keep_alive_active[0]:
            await asyncio.sleep(5)  # Ping every 5 seconds
            if keep_alive_active[0]:
                elapsed = asyncio.get_event_loop().time() - last_event_time[0]
                if elapsed >= 4:  # Only ping if no event sent recently
                    try:
                        await response.write(b': keepalive\n\n')
                        last_event_time[0] = asyncio.get_event_loop().time()
                    except Exception:
                        break  # Connection closed

    async def send_sse_data(data_dict):
        """Send SSE data, truncating if needed."""
        nonlocal last_event_time
        event_data = json.dumps(data_dict)
        if len(event_data) <= MAX_SSE_EVENT_SIZE:
            await response.write(f'data: {event_data}\n\n'.encode())
        else:
            summary = {
                "type": data_dict.get("type", "status"),
                "message": data_dict.get("message", "Processing...")[:500] + "...",
                "truncated": True
            }
            await response.write(f'data: {json.dumps(summary)}\n\n'.encode())
        last_event_time[0] = asyncio.get_event_loop().time()

    async def send_event(event):
        """Send streaming event to client."""
        event_type = event.get("type", "")

        if event_type == "system" and event.get("subtype") == "init":
            status = {"type": "status", "message": "Initializing..."}
            await send_sse_data(status)
        elif event_type == "assistant":
            msg = event.get("message", {})
            content = msg.get("content", [])
            for block in content:
                if block.get("type") == "tool_use":
                    tool_name = block.get("name", "tool")
                    status = {"type": "tool", "name": tool_name, "message": f"Using {tool_name}..."}
                    await send_sse_data(status)
        elif event_type == "user":
            msg = event.get("message", {})
            content = msg.get("content", [])
            for block in content:
                if block.get("type") == "tool_result":
                    result_content = block.get("content", "")
                    if isinstance(result_content, str) and len(result_content) > 100:
                        brief = result_content[:100].replace('\n', ' ') + "..."
                    elif isinstance(result_content, str):
                        brief = result_content.replace('\n', ' ')
                    else:
                        brief = "Got result"
                    status = {"type": "tool_result", "message": brief[:150]}
                    await send_sse_data(status)

    # Start keep-alive task
    ping_task = asyncio.create_task(keep_alive_task())

    try:
        data = await request.json()
        user_message = data.get("message", "").strip()

        if not user_message:
            await response.write(b'data: {"type":"error","message":"No message provided"}\n\n')
            return response

        logger.info(f"Message: {user_message[:50]}...")

        full_prompt = build_prompt(WEB_USER_ID, user_message)

        result, returncode, stderr = await call_claude_streaming(
            full_prompt,
            on_event=send_event
        )

        if returncode != 0 or not result:
            error_msg = stderr if stderr else "No response"
            error_msg = error_msg[:500].replace('"', '\\"').replace('\n', '\\n')
            await response.write(f'data: {{"type":"error","message":"{error_msg}"}}\n\n'.encode())
            return response

        # Clean response
        result = re.sub(r'\[ACTION:check_inbox(?::\d+)?\]\n?', '', result)
        result = re.sub(r'\[ACTION:send_email\|[^\]]+\]\n?', '', result)
        result = result.strip()

        # Save to history
        save_message(WEB_USER_ID, "user", user_message)
        save_message(WEB_USER_ID, "assistant", result)

        # Send final response (chunked if large)
        MAX_SSE_CHUNK = 16 * 1024
        if len(result) > MAX_SSE_CHUNK:
            for i in range(0, len(result), MAX_SSE_CHUNK):
                chunk = result[i:i + MAX_SSE_CHUNK]
                is_last = (i + MAX_SSE_CHUNK >= len(result))
                chunk_event = {
                    "type": "response_chunk" if not is_last else "response",
                    "content": chunk,
                    "partial": not is_last
                }
                await response.write(f'data: {json.dumps(chunk_event)}\n\n'.encode())
        else:
            final = {"type": "response", "content": result}
            await response.write(f'data: {json.dumps(final)}\n\n'.encode())

        # Send explicit end of stream signal
        await response.write(b'data: {"type":"done"}\n\n')

    except (ConnectionResetError, BrokenPipeError) as e:
        # Client disconnected - this is normal, don't log as error
        logger.debug(f"Client disconnected during stream: {e}")
    except Exception as e:
        error_str = str(e)
        # Check for transport closed errors (client disconnected)
        if "closing transport" in error_str.lower() or "connection reset" in error_str.lower():
            logger.debug(f"Client disconnected during stream: {e}")
        else:
            logger.error(f"Stream error: {e}")
            # Only try to write error if connection still open
            try:
                error_msg = error_str[:500].replace('"', '\\"').replace('\n', '\\n')
                await response.write(f'data: {{"type":"error","message":"{error_msg}"}}\n\n'.encode())
            except Exception:
                pass  # Connection already closed
    finally:
        # Stop keep-alive task
        keep_alive_active[0] = False
        ping_task.cancel()
        try:
            await ping_task
        except asyncio.CancelledError:
            pass

    return response


async def handle_upload(request):
    """Handle file uploads."""
    try:
        reader = await request.multipart()
        field = await reader.next()

        if field is None or field.name != 'file':
            return web.json_response({"error": "No file provided"}, status=400)

        filename = field.filename
        # Sanitize filename - remove non-ASCII and problematic chars
        safe_filename = re.sub(r'[^\w\s\-\.]', '', filename.encode('ascii', 'ignore').decode())
        safe_filename = safe_filename.strip() or 'upload'

        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        final_filename = f"{timestamp}_{safe_filename}"
        file_path = DOWNLOADS_DIR / final_filename

        size = 0
        with open(file_path, 'wb') as f:
            while True:
                chunk = await field.read_chunk()
                if not chunk:
                    break
                size += len(chunk)
                if size > 20 * 1024 * 1024:  # 20MB limit
                    file_path.unlink()
                    return web.json_response({"error": "File too large (max 20MB)"}, status=413)
                f.write(chunk)

        logger.info(f"Uploaded: {final_filename} ({size} bytes)")

        return web.json_response({
            "success": True,
            "filename": final_filename,
            "path": str(file_path),
            "size": size
        })

    except Exception as e:
        logger.error(f"Upload error: {e}")
        return web.json_response({"error": str(e)}, status=500)


async def handle_image(request):
    """Serve images from the filesystem."""
    path = request.query.get('path', '')

    if not path:
        return web.Response(text="No path specified", status=400)

    # Security: only allow certain directories
    path = Path(path).resolve()
    allowed_roots = [
        Path(DOWNLOADS_DIR).resolve(),
        Path(SCRIPT_DIR.parent).resolve(),  # thinx repo root
    ]

    allowed = any(
        str(path).startswith(str(root))
        for root in allowed_roots
    )

    if not allowed or not path.exists():
        return web.Response(text="File not found or not allowed", status=404)

    return web.FileResponse(path)


async def handle_static_file(request):
    """Serve static files from web directory (avatar.png, etc.)."""
    filename = request.match_info['filename']
    file_path = WEB_DIR / filename
    if file_path.exists() and file_path.is_file():
        return web.FileResponse(file_path)
    return web.Response(text="File not found", status=404)


async def handle_skills(request):
    """Serve the skills and features page."""
    skills_path = WEB_DIR / 'skills.html'
    if skills_path.exists():
        return web.FileResponse(skills_path)
    else:
        return web.Response(
            text="Skills page not found.",
            status=404
        )


async def handle_draw_bot(request):
    """Serve the Draw Bot interface."""
    draw_bot_path = WEB_DIR / 'draw_bot.html'
    if draw_bot_path.exists():
        return web.FileResponse(draw_bot_path)
    else:
        return web.Response(
            text="Draw Bot page not found.",
            status=404
        )


# Draw Bot profile path
DRAW_BOT_PROFILE = SCRIPT_DIR / 'profiles' / 'draw_bot.md'


def build_draw_bot_prompt(user_id: str, message: str) -> str:
    """Build the draw bot prompt with specialized diagramming context."""
    parts = []

    # Add system instructions for image display
    system_instructions = """<system_instructions>
You are Draw Bot, a specialized diagramming assistant. Your job is to create professional-quality diagrams.

When you create or reference an image file, output it using this format so it displays in the chat:
[ACTION:show_image|/full/path/to/image.png]

For example, after generating a diagram at /tmp/diagram.png, include:
[ACTION:show_image|/tmp/diagram.png]

The image will be rendered inline in the chat interface.
</system_instructions>"""
    parts.append(system_instructions)

    # Load draw_bot profile
    if DRAW_BOT_PROFILE.exists():
        try:
            with open(DRAW_BOT_PROFILE, 'r') as f:
                profile_content = f.read()
            parts.append(f"<draw_bot_profile>\n{profile_content}\n</draw_bot_profile>")
        except Exception as e:
            logger.warning(f"Could not read draw_bot profile: {e}")

    # Add diagramming behavior instructions
    diagram_instructions = """<behavior>
## Your Workflow

1. **Diagnostic Intake**: When the user first describes what they need, ask the diagnostic questions from your profile to clarify:
   - Purpose & audience
   - Diagram type
   - Style preference
   - Output format
   - Key elements to include

2. **Tool Selection**: Based on their answers, choose the appropriate tool:
   - D2 for clean architecture diagrams
   - Mermaid for sequences and flowcharts
   - nomnoml for hand-drawn/sketchy style
   - Structurizr for formal C4 architecture
   - PlantUML for UML diagrams

3. **Create the Diagram**: Generate the diagram code and render it using the appropriate skill (/d2, /mermaid, /kroki, etc.)

4. **Quality Check**: Verify against your checklist before delivering

5. **Iterate**: Ask if they want any adjustments

## Important Rules
- Always ask clarifying questions before creating the diagram (unless they've provided all needed info)
- Save diagrams to the diagrams/ directory with proper naming
- Use the ThinxAI color palette unless they request something different
- **ALWAYS use white (#FFFFFF) background by default for ALL diagrams** - this is mandatory unless user explicitly requests otherwise
- Show the rendered image using the [ACTION:show_image|path] format
</behavior>"""
    parts.append(diagram_instructions)

    # Load conversation history (draw_bot specific)
    history = load_history(f"{user_id}_draw_bot", limit=10)
    if history:
        history_text = "\n".join([
            f"{msg['role']}: {msg['content']}"
            for msg in history[-6:]  # Last 6 messages for tighter context
        ])
        parts.append(f"<conversation_history>\n{history_text}\n</conversation_history>")

    # Add current message
    parts.append(f"User message: {message}")

    return "\n\n".join(parts)


async def handle_draw_bot_stream(request):
    """Handle streaming message endpoint for Draw Bot."""
    response = web.StreamResponse(
        status=200,
        reason='OK',
        headers={
            'Content-Type': 'text/event-stream',
            'Cache-Control': 'no-cache',
            'Connection': 'keep-alive',
            'Access-Control-Allow-Origin': '*',
        }
    )
    await response.prepare(request)

    MAX_SSE_EVENT_SIZE = 16 * 1024

    async def send_sse_data(data_dict):
        """Send SSE data, truncating if needed."""
        event_data = json.dumps(data_dict)
        if len(event_data) <= MAX_SSE_EVENT_SIZE:
            await response.write(f'data: {event_data}\n\n'.encode())
        else:
            summary = {
                "type": data_dict.get("type", "status"),
                "message": data_dict.get("message", "Processing...")[:500] + "...",
                "truncated": True
            }
            await response.write(f'data: {json.dumps(summary)}\n\n'.encode())

    async def send_event(event):
        """Send streaming event to client."""
        event_type = event.get("type", "")

        if event_type == "system" and event.get("subtype") == "init":
            status = {"type": "status", "message": "Initializing Draw Bot..."}
            await send_sse_data(status)
        elif event_type == "assistant":
            msg = event.get("message", {})
            content = msg.get("content", [])
            for block in content:
                if block.get("type") == "tool_use":
                    tool_name = block.get("name", "tool")
                    status = {"type": "tool", "name": tool_name, "message": f"{tool_name}"}
                    await send_sse_data(status)
        elif event_type == "user":
            msg = event.get("message", {})
            content = msg.get("content", [])
            for block in content:
                if block.get("type") == "tool_result":
                    status = {"type": "tool_result", "message": "Got result"}
                    await send_sse_data(status)

    try:
        data = await request.json()
        user_message = data.get("message", "").strip()

        if not user_message:
            await response.write(b'data: {"type":"error","message":"No message provided"}\n\n')
            return response

        logger.info(f"Draw Bot: {user_message[:50]}...")

        full_prompt = build_draw_bot_prompt(WEB_USER_ID, user_message)

        result, returncode, stderr = await call_claude_streaming(
            full_prompt,
            on_event=send_event
        )

        if returncode != 0 or not result:
            error_msg = stderr if stderr else "No response"
            error_msg = error_msg[:500].replace('"', '\\"').replace('\n', '\\n')
            await response.write(f'data: {{"type":"error","message":"{error_msg}"}}\n\n'.encode())
            return response

        # Clean response
        result = re.sub(r'\[ACTION:check_inbox(?::\d+)?\]\n?', '', result)
        result = re.sub(r'\[ACTION:send_email\|[^\]]+\]\n?', '', result)
        result = result.strip()

        # Save to draw_bot history
        save_message(f"{WEB_USER_ID}_draw_bot", "user", user_message)
        save_message(f"{WEB_USER_ID}_draw_bot", "assistant", result)

        # Send final response (chunked if large)
        MAX_SSE_CHUNK = 16 * 1024
        if len(result) > MAX_SSE_CHUNK:
            for i in range(0, len(result), MAX_SSE_CHUNK):
                chunk = result[i:i + MAX_SSE_CHUNK]
                is_last = (i + MAX_SSE_CHUNK >= len(result))
                chunk_event = {
                    "type": "response_chunk" if not is_last else "response",
                    "content": chunk,
                    "partial": not is_last
                }
                await response.write(f'data: {json.dumps(chunk_event)}\n\n'.encode())
        else:
            final = {"type": "response", "content": result}
            await response.write(f'data: {json.dumps(final)}\n\n'.encode())

    except (ConnectionResetError, BrokenPipeError) as e:
        logger.debug(f"Client disconnected during Draw Bot stream: {e}")
    except Exception as e:
        error_str = str(e)
        if "closing transport" in error_str.lower() or "connection reset" in error_str.lower():
            logger.debug(f"Client disconnected during Draw Bot stream: {e}")
        else:
            logger.error(f"Draw Bot stream error: {e}")
            try:
                error_msg = error_str[:500].replace('"', '\\"').replace('\n', '\\n')
                await response.write(f'data: {{"type":"error","message":"{error_msg}"}}\n\n'.encode())
            except Exception:
                pass

    return response


def create_app():
    """Create the aiohttp application."""
    app = web.Application()

    # API routes
    app.router.add_get('/api/status', handle_status)
    app.router.add_get('/api/history', handle_history)
    app.router.add_post('/api/message/stream', handle_message_stream)
    app.router.add_post('/api/upload', handle_upload)
    app.router.add_get('/api/image', handle_image)

    # Draw Bot API
    app.router.add_post('/api/draw_bot/stream', handle_draw_bot_stream)

    # Static files and pages
    app.router.add_get('/', handle_index)
    app.router.add_get('/skills', handle_skills)
    app.router.add_get('/draw_bot', handle_draw_bot)
    app.router.add_get('/{filename}', handle_static_file)  # Serve files like avatar.png
    if WEB_DIR.exists():
        app.router.add_static('/static/', WEB_DIR, name='static')

    return app


async def main(host: str = '0.0.0.0', port: int = 8080):
    """Run the web server."""
    app = create_app()

    runner = web.AppRunner(app)
    await runner.setup()

    site = web.TCPSite(runner, host, port)
    await site.start()

    logger.info(f"ThinxAI Web Chat running at http://{host}:{port}")
    logger.info(f"Memory: {MEMORY_PATH}")
    logger.info(f"History: {HISTORY_DIR}")
    logger.info(f"Downloads: {DOWNLOADS_DIR}")

    # Keep running
    while True:
        await asyncio.sleep(3600)


if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser(description='ThinxAI Web Chat Server')
    parser.add_argument('--host', default='0.0.0.0', help='Host to bind to')
    parser.add_argument('--port', type=int, default=8080, help='Port to listen on')
    args = parser.parse_args()

    try:
        asyncio.run(main(host=args.host, port=args.port))
    except KeyboardInterrupt:
        logger.info("Shutting down...")
