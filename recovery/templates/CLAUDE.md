# Claude Code Instructions

## FIRST: Session Initialization

A **SessionStart hook** runs automatically when you start. It:
1. Generates your **Agent ID** (format: `Agent_YYYYMMDD_HHMM`)
2. Logs SESSION START to `memory/meta-context/current/vscode-claude.md`
3. Loads cross-agent context

**After the hook, you MUST manually read these files:**

```
Read: MEMORY.md
Read: memory/meta-context/current/telegram-bridge.md
Read: memory/meta-context/current/vscode-claude.md
```

Your Agent ID is in the most recent SESSION START entry in vscode-claude.md. Use it for all logging this session.

---

## Repository Structure

**Thinx** serves as a unified workspace for all of JD's work across four domains:

1. **ThinxAI Infrastructure** - Platform development, automation, integrations
2. **oddXian Apologetics** - Christian apologetics, young-earth geology ([research-programs/oddxian/](research-programs/oddxian/))
3. **AI Research** - AIDK Framework, AI limitations ([research-programs/ai-research/](research-programs/ai-research/))
4. **Logic Realism Theory** - L₃ ontological constraints, QM derivations ([research-programs/logic-realism/](research-programs/logic-realism/))

Research domains are located in [research-programs/](research-programs/) with full curation workflow and quality gates. See [research-programs/README.md](research-programs/README.md) for details.

## Cross-Agent Awareness (Meta-Context)

The Telegram bridge and VS Code Claude sessions share awareness through activity pools in `memory/meta-context/`.

### During Session

Log significant activity to `memory/meta-context/current/vscode-claude.md`:

- **Task changes:** When starting or completing major tasks
- **Milestones:** Significant progress or blockers
- **Context switches:** Moving between projects/repos

**Entry Format:**
```markdown
---

## HH:MM:SS | Agent_YYYYMMDD_HHMM | <repo or context>
**What:** <action summary>
**Why:** <user request or trigger>
**Duration:** <time or "ongoing">
**Context:** <relevant details>

---
```

### Archive Structure

- `current/` - Today's live activity files
- `archive/YYYY-MM/` - Daily files by month
- `archive/YYYY-QN/` - Quarterly archives (monthly folders)

### Don't Over-Log

Log meaningful events, not every tool call. Good candidates:
- Session start/end
- Major task begins (e.g., "Implementing feature X")
- Task completion or blocker
- Switching between repos or domains

## Git Discipline

**All agents must track and commit changes:**

1. **Before starting work:** Run `git status` to see current state
2. **After completing a feature/fix:** Stage and commit relevant files
3. **Commit messages:** Use clear, descriptive messages:
   ```
   Add feature X with Y support

   - Bullet point details
   - What was changed and why

   Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
   ```
4. **Don't batch unrelated changes:** Commit features separately
5. **Don't commit generated/temp files:** Check `.gitignore` patterns
6. **Ask before pushing:** Only push to remote when explicitly requested

When user asks "are you tracking changes?" or similar - run `git status` and offer to commit.

## Thinx Tuning Sessions

**IMPORTANT: At the start of each collaboration, create a new session log or update the current session.**

When working on thinx tuning tasks:

1. **Session Logging**
   - Create session log in `thinx_tuning/sessions/` with naming `yyyymmdd_HHMMSS.md`
   - **Update session log every 3 minutes** during active tuning work
   - Include: objectives, completed tasks, files modified, notes

2. **Backups**
   - Create backup in `thinx_tuning/backups/yyyy-mm-dd/` before major changes

3. **VS Code Extension**
   - Always use `vsce package` + `code --install-extension` (never copy files directly)
   - Keep internal IDs unchanged; only modify user-facing titles
