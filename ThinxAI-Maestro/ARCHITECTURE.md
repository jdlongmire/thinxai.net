# ThinxAI-Maestro Architecture

## Core Principle: Expert-Curated, AI-Enabled (ECAE)

> AI agents are **derivative actors** that amplify human expertise. They cannot originate knowledge, policy, or authority—only transform, execute, and report based on expert-defined constraints.

> The agent's outputs must be grounded in authoritative systems of record and observed reality. If it cannot cite what it saw (ticket, metric, log line, config state, change record), it should not act.

## Agent Classification: Passive vs Active

| Type | Autonomy | RBAC | State Changes | Examples |
|------|----------|------|---------------|----------|
| **Passive** | Full (observation) | None | No | HealthMonitor, GitWatcher, TaskDigest |
| **Active** | Constrained | Yes | Yes | Executor, ChangeDeployer, AutoScaler |

### ECAE Role Mapping

| Aspect | Expert (Human) | AI Agent |
|--------|----------------|----------|
| Policy definition | Creates, modifies | Enforces, reports violations |
| Knowledge authority | Originates, validates | Derives, cites, flags uncertainty |
| Decision making | Approves, overrides | Recommends, executes with approval |
| Accountability | Responsible | Traceable (auditable) |

## System Components

```
┌───────────────────────────────────────────────────────────────────────┐
│                          WEB UI (Browser)                              │
│  Dashboard │ Agents │ Escalations │ Knowledge │ Chat │ Settings       │
└───────────────────────────────────┬───────────────────────────────────┘
                                    │ REST API + WebSocket
                                    ▼
┌───────────────────────────────────────────────────────────────────────┐
│                         FastAPI Backend                                │
│     Auth/RBAC │ Agent API │ Chat NLP │ Knowledge API │ Config API     │
└───────────────────────────────────┬───────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────┐
│                     Expert (Human)                          │
│         Defines policies, approves escalations              │
└─────────────────────────┬───────────────────────────────────┘
                          │ curates
          ┌───────────────┴───────────────┐
          │                               │
          ▼                               ▼
┌─────────────────────────┐     ┌─────────────────────────┐
│    PASSIVE AGENTS       │     │     ACTIVE AGENTS       │
│  (Autonomous Observers) │     │   (RBAC Controlled)     │
├─────────────────────────┤     ├─────────────────────────┤
│ HealthMonitor           │     │ Executor                │
│ SessionCurator          │────▶│ ChangeDeployer          │
│ GitWatcher              │esc- │ RemediationAgent        │
│ BackupVerifier          │alate│ AutoScaler              │
│ TaskDigest              │     │                         │
└─────────────────────────┘     └───────────┬─────────────┘
          │                                 │
          │ observe                         │ act (with approval)
          ▼                                 ▼
┌─────────────────────────────────────────────────────────────┐
│                    Systems of Record                         │
│        (Metrics, Logs, Git, ITSM, Infrastructure)           │
└─────────────────────────────────────────────────────────────┘
```

## Agent Base Contract

```python
from abc import ABC, abstractmethod
from dataclasses import dataclass
from datetime import datetime
from typing import Any

@dataclass
class Evidence:
    """Structured evidence from agent execution."""
    agent: str
    run_id: str
    triggered_by: str  # "schedule" | "adhoc" | "agent:<name>"
    timestamp: datetime
    evidence: dict[str, Any]
    conclusions: list[str]
    actions_taken: list[dict]
    recommendations: list[str]
    next_steps: list[str]

class AgentRole(Enum):
    PASSIVE = "passive"    # Read-only, autonomous observation
    ACTIVE = "active"      # State-changing, RBAC controlled

class Agent(ABC):
    """Base class for all ThinxAI-Maestro agents (ECAE-governed)."""

    name: str
    role: AgentRole        # Passive or Active
    description: str
    tools: list[str]       # Tool names this agent can use

    @abstractmethod
    def run(self, context: dict) -> Evidence:
        """Execute agent and return structured evidence."""
        pass

    def can_schedule(self) -> bool:
        """Whether this agent supports scheduled runs."""
        return True

    def schedule_config(self) -> dict | None:
        """Default schedule configuration."""
        return None

    def validate_context(self, context: dict) -> bool:
        """Validate required context before execution."""
        return True

    def can_escalate_to(self, active_agent: str) -> bool:
        """Check if this passive agent can escalate to an active agent."""
        return self.role == AgentRole.PASSIVE  # Policy lookup in practice
```

## Tool Categories

### Observability
- `get_service_status(service_name)` → systemctl + health check
- `get_recent_logs(service, window, filter)` → journalctl wrapper
- `get_system_metrics()` → CPU, mem, disk, network

### Git Operations
- `get_git_changes(repo, since)` → Recent commits/diffs
- `get_uncommitted_changes(repo)` → Working tree status
- `create_pr(repo, branch, title, body)` → Draft PR

### Task Management
- `get_scheduled_tasks()` → crontab + systemd timers
- `create_task_note(title, description)` → Legato task
- `update_task_status(entry_id, status)` → Close loop

### Notifications
- `send_email(to, subject, body)` → SMTP
- `send_alert(severity, message)` → Alert routing

### External Systems (via SystemConnector)
- `query_external(source, action, params)` → Normalized query
- `correlate_alerts(sources, window)` → Cross-platform

## Privilege Tiers (RBAC)

| Tier | Agent Type | Capability | Examples |
|------|------------|------------|----------|
| 0 - Read-only | Passive | Query systems, summarize evidence | get_metrics, get_logs |
| 1 - Suggest | Passive | Propose changes, draft PRs, escalate | create_pr (draft), escalation_request |
| 2 - Execute-with-approval | Active | Run bounded automations after approval | restart_service, scale_within_bounds |
| 3 - Pre-authorized | Active | Low-risk actions within policy bounds | clear_cache, rotate_logs |

**Default:** Passive agents start at Tier 0 (read-only). Active agents require RBAC policy.

### RBAC Policy Structure

```yaml
# config/rbac-policies.yaml
policies:
  auto-restart:
    description: "Auto-restart non-critical services if down < 5 min"
    active_agent: executor
    trigger_agent: health-monitor
    conditions:
      service_criticality: low
      downtime_minutes: "<5"
      environment: ["dev", "staging"]
    action: restart_service
    max_attempts: 3
    cooldown_minutes: 30
```

## Evidence Schema

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "agent": {"type": "string"},
    "run_id": {"type": "string", "pattern": "^[a-z-]+_[0-9]{8}_[0-9]{6}$"},
    "triggered_by": {"type": "string"},
    "timestamp": {"type": "string", "format": "date-time"},
    "evidence": {
      "type": "object",
      "properties": {
        "metrics": {"type": "object"},
        "logs": {"type": "array", "items": {"type": "object"}},
        "configs": {"type": "object"},
        "commands": {"type": "array", "items": {"type": "object"}}
      }
    },
    "conclusions": {"type": "array", "items": {"type": "string"}},
    "actions_taken": {"type": "array", "items": {"type": "object"}},
    "recommendations": {"type": "array", "items": {"type": "string"}},
    "next_steps": {"type": "array", "items": {"type": "string"}}
  },
  "required": ["agent", "run_id", "triggered_by", "timestamp", "evidence"]
}
```

## File Structure

```
thinxai/
├── agents/
│   ├── base.py                  # Agent base class with role
│   ├── rbac.py                  # RBAC enforcer
│   ├── escalation.py            # Escalation request handling
│   ├── passive/                 # Tier 0-1: Autonomous observers
│   │   ├── health_monitor.py
│   │   ├── session_curator.py
│   │   ├── git_watcher.py
│   │   ├── backup_verifier.py
│   │   ├── task_digest.py
│   │   ├── incident_investigator.py
│   │   ├── report_generator.py
│   │   └── diagram_renderer.py
│   ├── active/                  # Tier 2-3: RBAC controlled
│   │   ├── executor.py
│   │   ├── change_deployer.py
│   │   ├── remediation_agent.py
│   │   └── auto_scaler.py
│   └── system_connector.py
├── connectors/
│   ├── base.py                  # Connector interface
│   ├── registry.py              # Connector discovery
│   ├── local.py                 # Local system tools
│   ├── solarwinds.py
│   ├── prometheus.py
│   └── ...
├── knowledge/                    # Tiered RAG components
│   ├── orchestrator.py           # Routes queries across tiers
│   ├── query.py                  # KnowledgeQuery interface
│   ├── tiers/
│   │   ├── base.py               # TierStore abstract class
│   │   ├── internal.py           # Tier 1: ChromaDB/Qdrant
│   │   ├── specialized.py        # Tier 2: CVE, vendor docs
│   │   └── internet.py           # Tier 3: Web search
│   ├── ingestion/
│   │   ├── manager.py            # IngestionManager
│   │   ├── queue.py              # Async ingestion queue
│   │   ├── processors/           # Content parsers
│   │   │   ├── markdown.py
│   │   │   ├── json.py
│   │   │   └── html.py
│   │   └── sources/              # External source connectors
│   │       ├── base.py           # KnowledgeSource ABC
│   │       ├── nvd.py            # CVE/NVD database
│   │       ├── msdocs.py         # Microsoft Learn
│   │       ├── github.py         # GitHub issues
│   │       └── web_search.py     # Brave/Google API
│   ├── embeddings/
│   │   ├── local.py              # sentence-transformers
│   │   └── cache.py              # Embedding cache
│   └── collections/
│       ├── incidents.py
│       ├── baselines.py
│       ├── runbooks.py
│       ├── changes.py
│       └── evidence.py
├── data/
│   ├── vectordb/
│   │   ├── internal/             # Tier 1 storage
│   │   └── specialized/          # Tier 2 storage
│   └── ingestion/
│       ├── queue/                # Pending ingestion
│       └── failed/               # Failed for retry
├── tools/
│   ├── observability.py
│   ├── git_ops.py
│   ├── task_management.py
│   └── notifications.py
├── scheduler/
│   ├── runner.py                # Agent execution
│   └── manifest.yaml            # Schedule definitions
├── evidence/
│   └── YYYY-MM/
│       └── DD/
│           └── agent_HHMMSS.json
├── config/
│   ├── agents.yaml              # Agent configuration
│   └── connectors.yaml          # External credentials
└── web/
    ├── frontend/                # Vue 3 SPA
    │   ├── src/
    │   │   ├── components/
    │   │   │   ├── Dashboard/
    │   │   │   ├── Agents/
    │   │   │   ├── Escalations/
    │   │   │   ├── Knowledge/
    │   │   │   ├── Chat/
    │   │   │   └── Settings/
    │   │   ├── stores/          # Pinia state
    │   │   ├── api/             # API client
    │   │   └── router/
    │   └── package.json
    └── backend/                 # FastAPI
        ├── app/
        │   ├── main.py
        │   ├── auth/            # OAuth2 + JWT
        │   ├── api/             # REST endpoints
        │   ├── chat/            # NLP pipeline
        │   │   ├── session.py
        │   │   ├── intent.py
        │   │   ├── entities.py
        │   │   ├── actions.py
        │   │   └── response.py
        │   └── models/
        └── requirements.txt
```

## Safety Controls

### Guardrails (Pre-execution)
- Policy checks before tool calls
- Scope validation (environment, blast radius)
- Privilege tier enforcement

### Runtime Checks
- "Are we in prod?"
- "Is there an active incident?"
- "Is this within policy?"

### Post-Action Verification
- SLO recovery validation
- Error rate monitoring
- Automatic rollback triggers

### Audit
- All tool calls logged with inputs/outputs
- Evidence bundles stored with each run
- Change records linked to ITSM
