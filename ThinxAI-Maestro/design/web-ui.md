# ThinxAI-Maestro Web UI Design

## Overview

The web interface serves as the **primary human touchpoint** for ThinxAI-Maestro, providing:
1. **Configuration** - Manage agents, policies, connectors, and knowledge sources
2. **Operations** - Monitor agent activity, view evidence, approve escalations
3. **Chatbot Interface** - AI-guided NLP for natural language operations

All interactions maintain ECAE principles: the UI is for experts to curate and approve, not for AI to act autonomously.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          Browser (SPA)                                  │
│  ┌─────────────────────────────────────────────────────────────────────┐│
│  │  Vue 3 / React          │  TailwindCSS   │  WebSocket Client       ││
│  └─────────────────────────────────────────────────────────────────────┘│
└────────────────────────────────────┬────────────────────────────────────┘
                                     │ REST API + WebSocket
                                     ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                        FastAPI Backend                                   │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐ │
│  │ Auth/RBAC   │  │ Agent API   │  │ Chat API    │  │ Config API      │ │
│  │ (OAuth/JWT) │  │             │  │ (NLP)       │  │                 │ │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────────┘ │
│                          │                │                              │
│                          ▼                ▼                              │
│  ┌─────────────────────────────────────────────────────────────────────┐│
│  │                    Agent Orchestrator                                ││
│  │  (Scheduler, RBAC Enforcer, Escalation Manager, Evidence Store)     ││
│  └─────────────────────────────────────────────────────────────────────┘│
│                          │                                               │
│                          ▼                                               │
│  ┌─────────────────────────────────────────────────────────────────────┐│
│  │            Knowledge Orchestrator (Tiered RAG)                       ││
│  │       (Internal │ Specialized │ Internet with trust scores)         ││
│  └─────────────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Page Structure

### 1. Dashboard (`/`)

Real-time system overview:

```
┌────────────────────────────────────────────────────────────────┐
│  ThinxAI-Maestro                           [🔔 2] [👤 JD] [⚙️] │
├────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐   │
│  │ AGENTS          │ │ ESCALATIONS     │ │ KNOWLEDGE       │   │
│  │ 5 Active        │ │ 2 Pending       │ │ 1,247 docs      │   │
│  │ 3 Passive       │ │ 1 Critical      │ │ Last sync: 5m   │   │
│  └─────────────────┘ └─────────────────┘ └─────────────────┘   │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ RECENT ACTIVITY                                           │  │
│  │                                                           │  │
│  │ 14:32 HealthMonitor    nginx: 200ms response, healthy     │  │
│  │ 14:30 GitWatcher       thinx: 2 new commits               │  │
│  │ 14:28 TaskDigest       3 pending tasks summarized         │  │
│  │ 14:15 HealthMonitor    ⚠️ redis latency spike (escalated) │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌────────────────────────────────────────────────────────┐    │
│  │ 💬 Chat with Maestro                                   │    │
│  │ ─────────────────────────────────────────────────────  │    │
│  │ How can I help you today?                              │    │
│  │                                                         │    │
│  │ [Type your message...]                         [Send]  │    │
│  └────────────────────────────────────────────────────────┘    │
└────────────────────────────────────────────────────────────────┘
```

**Features:**
- Live agent status tiles (click to expand)
- Pending escalation counter with priority badges
- Knowledge base health indicator
- Activity stream (WebSocket-powered)
- Inline chat widget (expandable)

---

### 2. Agents (`/agents`)

Agent management and monitoring:

```
┌────────────────────────────────────────────────────────────────┐
│  Agents                                        [+ New Agent]   │
├────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Filter: [All ▾] [Passive ▾] [Active ▾]       Search: [____]  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ HealthMonitor                              Passive  ✓ ON  │  │
│  │ Monitors system health metrics and service availability  │  │
│  │                                                           │  │
│  │ Schedule: */5 * * * *   Last run: 2 min ago   Status: OK │  │
│  │ Tools: get_system_metrics, get_service_status            │  │
│  │                                                           │  │
│  │ [View Evidence] [Edit Schedule] [Run Now]                │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Executor                                   Active  ⚡ RBAC │  │
│  │ Executes approved remediation actions                     │  │
│  │                                                           │  │
│  │ Schedule: On demand   Last run: 1 hr ago   Status: IDLE  │  │
│  │ Permissions: restart_service (dev,staging), clear_cache  │  │
│  │                                                           │  │
│  │ [View Evidence] [Edit Permissions] [View Audit Log]      │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
└────────────────────────────────────────────────────────────────┘
```

**Agent Detail Modal:**
- Configuration editor (YAML)
- Tool bindings
- Schedule cron editor
- Permission grants (for active agents)
- Evidence history
- Escalation history

---

### 3. Escalations (`/escalations`)

Approval queue for active agent actions:

```
┌────────────────────────────────────────────────────────────────┐
│  Escalations                           Pending: 2 | Today: 5   │
├────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ 🔴 CRITICAL                              14:15 | 45m ago │  │
│  │ ─────────────────────────────────────────────────────────│  │
│  │ Source: HealthMonitor                                     │  │
│  │ Target: Executor → restart_service                        │  │
│  │                                                           │  │
│  │ Justification:                                            │  │
│  │ Redis responding with latency >500ms for 10 minutes.      │  │
│  │ Current avg: 823ms. SLO target: <100ms.                   │  │
│  │                                                           │  │
│  │ Evidence: [View health_20260207_141500.json]              │  │
│  │                                                           │  │
│  │ Recommended Action:                                       │  │
│  │ systemctl restart redis-server                            │  │
│  │                                                           │  │
│  │ [✓ Approve] [✓ Approve with Note] [✗ Deny] [⏸ Snooze]   │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ 🟡 HIGH                                  14:28 | 32m ago │  │
│  │ ─────────────────────────────────────────────────────────│  │
│  │ Source: GitWatcher                                        │  │
│  │ Target: ChangeDeployer → create_pr                        │  │
│  │ ...                                                       │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
└────────────────────────────────────────────────────────────────┘
```

**Features:**
- Priority-sorted queue
- Evidence inline preview
- One-click approve/deny
- "Approve with modifications" option
- Audit trail for all decisions

---

### 4. Knowledge (`/knowledge`)

RAG tier management and ingestion:

```
┌────────────────────────────────────────────────────────────────┐
│  Knowledge Base                                                 │
├────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────┐ ┌─────────────────────┐               │
│  │ Tier 1: Internal    │ │ Tier 2: Specialized │               │
│  │ 847 documents       │ │ 12 sources active   │               │
│  │ Trust: 100%         │ │ Trust: 90-95%       │               │
│  │ [Browse] [Ingest]   │ │ [Configure]         │               │
│  └─────────────────────┘ └─────────────────────┘               │
│                                                                 │
│  ┌─────────────────────┐                                       │
│  │ Tier 3: Internet    │                                       │
│  │ Status: Opt-in      │                                       │
│  │ Trust: 50-80%       │                                       │
│  │ [Configure Filters] │                                       │
│  └─────────────────────┘                                       │
│                                                                 │
│  ─────────────────────────────────────────────────────────────  │
│                                                                 │
│  INGESTION QUEUE                                               │
│                                                                 │
│  │ Source                │ Status    │ Last Run    │ Actions │ │
│  │───────────────────────│───────────│─────────────│─────────│ │
│  │ git-evidence          │ ✓ Active  │ 2 min ago   │ [⟲] [⚙] │ │
│  │ runbook-folder        │ ✓ Active  │ 1 hr ago    │ [⟲] [⚙] │ │
│  │ nvd-cve-feed          │ ⚡ Syncing │ now         │ [⏸] [⚙] │ │
│  │ ms-learn-dotnet       │ ⏸ Paused  │ 3 days ago  │ [▶] [⚙] │ │
│                                                                 │
└────────────────────────────────────────────────────────────────┘
```

**Tier 1 Browser:**
- Collection tree (incidents, runbooks, baselines, etc.)
- Document preview
- Manual document ingestion (file upload, paste)
- Embedding status

**Tier 2 Config:**
- Source connectors (NVD, MS Learn, vendor docs)
- Sync schedules
- Trust score overrides

**Tier 3 Config:**
- Allowed/blocked domains
- Search provider (Brave, Google)
- Query logging

---

### 5. Chat Interface (`/chat`)

Full-page NLP interface with conversation history:

```
┌────────────────────────────────────────────────────────────────┐
│  Maestro Chat                               [New Conversation] │
├────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐  ┌─────────────────────────────────────────┐ │
│  │ History      │  │                                         │ │
│  │              │  │  🤖 Maestro                             │ │
│  │ Today        │  │  How can I help you with ThinxAI       │ │
│  │ ├ Redis...   │  │  operations today?                      │ │
│  │ └ Agent...   │  │                                         │ │
│  │              │  │  ─────────────────────────────────────  │ │
│  │ Yesterday    │  │                                         │ │
│  │ ├ Deploy...  │  │  👤 You                                 │ │
│  │ └ Health...  │  │  What's the status of the redis        │ │
│  │              │  │  service?                               │ │
│  │              │  │                                         │ │
│  │              │  │  ─────────────────────────────────────  │ │
│  │              │  │                                         │ │
│  │              │  │  🤖 Maestro                             │ │
│  │              │  │  I'll check the HealthMonitor evidence  │ │
│  │              │  │  for redis.                             │ │
│  │              │  │                                         │ │
│  │              │  │  ┌─────────────────────────────────┐   │ │
│  │              │  │  │ 📊 Redis Status                 │   │ │
│  │              │  │  │ Status: Degraded ⚠️              │   │ │
│  │              │  │  │ Latency: 823ms (SLO: <100ms)    │   │ │
│  │              │  │  │ Uptime: 14 days                 │   │ │
│  │              │  │  │ Last check: 2 min ago           │   │ │
│  │              │  │  │                                  │   │ │
│  │              │  │  │ [View Full Evidence]            │   │ │
│  │              │  │  └─────────────────────────────────┘   │ │
│  │              │  │                                         │ │
│  │              │  │  There's a pending escalation to       │ │
│  │              │  │  restart redis. Would you like me      │ │
│  │              │  │  to show you the approval queue?       │ │
│  │              │  │                                         │ │
│  │              │  │  [Show Escalations] [Approve Restart]  │ │
│  │              │  │                                         │ │
│  └──────────────┘  └─────────────────────────────────────────┘ │
│                                                                 │
│  ┌────────────────────────────────────────────────────────────┐│
│  │ Ask Maestro...                                     [Send] ││
│  └────────────────────────────────────────────────────────────┘│
│                                                                 │
│  Quick Actions: [System Status] [Pending Tasks] [Recent Alerts]│
└────────────────────────────────────────────────────────────────┘
```

---

## Chatbot Capabilities

### NLP Intent Categories

| Intent | Example Queries | Backend Action |
|--------|-----------------|----------------|
| **Status Query** | "What's the status of nginx?" | Query HealthMonitor evidence |
| **Evidence Lookup** | "Show me yesterday's incidents" | Search evidence store |
| **Knowledge Search** | "How do I restart redis safely?" | RAG query (Tier 1 → 2 → 3) |
| **Escalation Management** | "Approve the redis restart" | Update escalation status |
| **Agent Control** | "Run HealthMonitor now" | Trigger ad-hoc agent run |
| **Configuration** | "Add a new alert threshold" | Edit config (with confirmation) |
| **Explanation** | "Why did the backup fail?" | Correlate evidence + RAG |

### Conversational Flow

```python
class ChatSession:
    """Manages a chat conversation with context."""

    def __init__(self, user_id: str):
        self.user_id = user_id
        self.messages: list[ChatMessage] = []
        self.context: dict = {}  # Current entities, pending actions

    async def process_message(self, text: str) -> ChatResponse:
        """
        Process user message through NLP pipeline.

        1. Intent classification
        2. Entity extraction (agent names, services, dates)
        3. Context resolution (pronouns, references)
        4. Action planning
        5. Execution or confirmation request
        6. Response generation
        """
        intent = await self.classify_intent(text)
        entities = await self.extract_entities(text)

        # Resolve references like "it", "that agent", "the escalation"
        resolved = self.resolve_references(entities)

        # Plan action based on intent
        action_plan = await self.plan_action(intent, resolved)

        # Check if action requires confirmation
        if action_plan.requires_confirmation:
            self.context["pending_action"] = action_plan
            return ChatResponse(
                text=f"I'll {action_plan.description}. Confirm?",
                actions=[
                    QuickAction("Confirm", "confirm"),
                    QuickAction("Cancel", "cancel")
                ]
            )

        # Execute and respond
        result = await action_plan.execute()
        response = await self.generate_response(result)

        self.messages.append(ChatMessage("user", text))
        self.messages.append(ChatMessage("assistant", response.text))

        return response
```

### Response Components

Chat responses can include rich components:

```python
class ChatResponse:
    text: str                      # Natural language response
    evidence_cards: list[dict]     # Inline evidence displays
    quick_actions: list[QuickAction]  # Clickable action buttons
    suggestions: list[str]         # Follow-up suggestions
    raw_data: Optional[dict]       # Expandable JSON

class QuickAction:
    label: str          # Button text
    action: str         # Action identifier
    params: dict = {}   # Pre-filled parameters
    confirm: bool = False  # Require confirmation
```

### ECAE Enforcement in Chat

The chatbot **cannot**:
- Execute active agent actions without explicit approval
- Modify RBAC policies through natural language
- Override escalation denials
- Access Tier 3 (internet) knowledge without permission

The chatbot **can**:
- Query any passive agent evidence
- Search all knowledge tiers (respecting permissions)
- Present escalations for approval
- Execute pre-authorized actions after confirmation

```python
class ChatRBACMiddleware:
    """Enforce ECAE principles in chat interactions."""

    def check_action(self, user: User, action: ActionPlan) -> Permission:
        if action.modifies_state:
            # Active actions need explicit approval
            if action.has_pre_authorization(user):
                return Permission.CONFIRM_REQUIRED
            return Permission.APPROVAL_REQUIRED

        if action.accesses_tier3:
            # Internet access is opt-in
            if not user.tier3_enabled:
                return Permission.DENIED

        return Permission.ALLOWED
```

---

## Configuration UI

### 6. Settings (`/settings`)

System-wide configuration:

```
┌────────────────────────────────────────────────────────────────┐
│  Settings                                                       │
├────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌────────────────┐                                            │
│  │ General        │  System Configuration                      │
│  │ ────────────── │  ──────────────────────────────────────── │
│  │ ▸ Authentication│                                           │
│  │ ▸ Notifications │  Timezone: [America/Chicago       ▾]     │
│  │ ▸ Integrations  │  Evidence Retention: [90 days      ▾]     │
│  │                 │  Log Level: [INFO              ▾]          │
│  │ Agents          │                                            │
│  │ ────────────── │  ──────────────────────────────────────── │
│  │ ▸ Schedules     │                                            │
│  │ ▸ RBAC Policies │  Default Agent Timeout: [300 seconds]     │
│  │ ▸ Tools         │  Max Concurrent Agents: [5              ] │
│  │                 │                                            │
│  │ Knowledge       │  ──────────────────────────────────────── │
│  │ ────────────── │                                            │
│  │ ▸ Tier 1 Config │  Enable Tier 3 (Internet): [✓]            │
│  │ ▸ Tier 2 Sources│  Tier 3 Trust Threshold: [70%       ]     │
│  │ ▸ Tier 3 Filters│                                            │
│  │                 │                                            │
│  │ Chat            │  ──────────────────────────────────────── │
│  │ ────────────── │                                            │
│  │ ▸ NLP Model     │  Chat Model: [claude-3-opus      ▾]       │
│  │ ▸ Quick Actions │  Conversation History: [30 days    ▾]     │
│  │                 │                                            │
│  └────────────────┘  [Save Changes]                            │
│                                                                 │
└────────────────────────────────────────────────────────────────┘
```

### RBAC Policy Editor

```
┌────────────────────────────────────────────────────────────────┐
│  RBAC Policies                                   [+ New Policy] │
├────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ auto-restart                                     [Edit]  │  │
│  │ ─────────────────────────────────────────────────────────│  │
│  │ Active Agent: Executor                                    │  │
│  │ Trigger: HealthMonitor                                    │  │
│  │ Action: restart_service                                   │  │
│  │                                                           │  │
│  │ Conditions:                                               │  │
│  │   • service_criticality: low                              │  │
│  │   • downtime_minutes: < 5                                 │  │
│  │   • environment: dev, staging                             │  │
│  │                                                           │  │
│  │ Limits: 3 attempts, 30 min cooldown                       │  │
│  │                                                           │  │
│  │ Status: ✓ Active        Last triggered: 2 days ago       │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
└────────────────────────────────────────────────────────────────┘
```

---

## Technical Stack

### Frontend

| Layer | Technology | Rationale |
|-------|------------|-----------|
| Framework | Vue 3 + Composition API | Reactive, TypeScript-friendly |
| UI Components | Headless UI + TailwindCSS | Accessible, customizable |
| State | Pinia | Simple, TypeScript-native |
| WebSocket | Socket.io-client | Real-time updates |
| Charts | Chart.js / Recharts | Evidence visualization |
| Markdown | Marked + highlight.js | Chat message formatting |

### Backend

| Layer | Technology | Rationale |
|-------|------------|-----------|
| Framework | FastAPI | Async, OpenAPI, Pydantic |
| Auth | OAuth2 + JWT | Enterprise SSO ready |
| WebSocket | FastAPI WebSocket | Real-time agent updates |
| Chat NLP | Claude API / local LLM | Intent + response generation |
| Database | PostgreSQL | Config, users, audit log |
| Cache | Redis | Session state, real-time |

### API Structure

```
/api/v1/
├── auth/
│   ├── login
│   ├── logout
│   └── refresh
├── agents/
│   ├── GET /                    # List agents
│   ├── GET /{id}                # Agent detail
│   ├── PUT /{id}/config         # Update config
│   ├── POST /{id}/run           # Trigger ad-hoc
│   └── GET /{id}/evidence       # Evidence history
├── escalations/
│   ├── GET /                    # Pending escalations
│   ├── POST /{id}/approve       # Approve
│   ├── POST /{id}/deny          # Deny
│   └── GET /history             # Audit log
├── knowledge/
│   ├── GET /tiers               # Tier status
│   ├── POST /query              # RAG query
│   ├── POST /ingest             # Manual ingest
│   └── GET /sources             # Configured sources
├── chat/
│   ├── POST /message            # Send message
│   ├── GET /history             # Conversation history
│   └── WebSocket /stream        # Streaming responses
└── settings/
    ├── GET /                    # All settings
    └── PUT /                    # Update settings
```

---

## Security

### Authentication Flow

```
┌──────────┐     ┌──────────┐     ┌──────────┐
│ Browser  │────▶│ FastAPI  │────▶│ OAuth    │
│          │◀────│ (JWT)    │◀────│ Provider │
└──────────┘     └──────────┘     └──────────┘
```

- OAuth2 for enterprise SSO (Azure AD, Okta)
- JWT tokens with short expiry (15 min)
- Refresh tokens in HTTP-only cookies
- RBAC enforced at API layer

### Chat Security

- All chat actions logged with user + timestamp
- State-modifying actions require re-authentication
- Sensitive config changes require 2FA
- Conversation history encrypted at rest

---

## File Structure

```
thinxai-maestro/
├── web/
│   ├── frontend/              # Vue 3 SPA
│   │   ├── src/
│   │   │   ├── components/
│   │   │   │   ├── Dashboard/
│   │   │   │   ├── Agents/
│   │   │   │   ├── Escalations/
│   │   │   │   ├── Knowledge/
│   │   │   │   ├── Chat/
│   │   │   │   │   ├── ChatWindow.vue
│   │   │   │   │   ├── MessageBubble.vue
│   │   │   │   │   ├── QuickActions.vue
│   │   │   │   │   ├── EvidenceCard.vue
│   │   │   │   │   └── ConversationHistory.vue
│   │   │   │   └── Settings/
│   │   │   ├── stores/
│   │   │   │   ├── agents.ts
│   │   │   │   ├── escalations.ts
│   │   │   │   ├── chat.ts
│   │   │   │   └── auth.ts
│   │   │   ├── api/
│   │   │   │   └── client.ts
│   │   │   └── router/
│   │   │       └── index.ts
│   │   └── package.json
│   │
│   └── backend/               # FastAPI
│       ├── app/
│       │   ├── main.py
│       │   ├── auth/
│       │   │   ├── oauth.py
│       │   │   └── jwt.py
│       │   ├── api/
│       │   │   ├── agents.py
│       │   │   ├── escalations.py
│       │   │   ├── knowledge.py
│       │   │   ├── chat.py
│       │   │   └── settings.py
│       │   ├── chat/
│       │   │   ├── session.py
│       │   │   ├── intent.py
│       │   │   ├── entities.py
│       │   │   ├── actions.py
│       │   │   └── response.py
│       │   ├── models/
│       │   └── db/
│       └── requirements.txt
│
├── agents/
├── knowledge/
└── config/
```

---

## Summary

| Component | Purpose | ECAE Role |
|-----------|---------|-----------|
| Dashboard | Real-time overview | Expert situational awareness |
| Agents | Configuration + monitoring | Expert defines, AI executes |
| Escalations | Approval queue | Expert approves actions |
| Knowledge | RAG management | Expert curates sources |
| Chat | NLP interface | AI assists, expert decides |
| Settings | System config | Expert controls all |

**Key Principle:** The web UI puts the expert in control. The chatbot assists with queries and presents options, but all consequential actions flow through explicit approval gates.
