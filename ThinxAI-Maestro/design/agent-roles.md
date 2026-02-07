# Agent Roles: Passive, Active, and ECAE Governance

## Core Principle: Expert-Curated, AI-Enabled (ECAE)

> AI agents are **derivative actors** that amplify human expertise. They cannot originate knowledge, policy, or authority—only transform, execute, and report based on expert-defined constraints.

This is the ThinxAI-specific application of the AIDK Framework's origination/derivation distinction:
- **Humans** access I∞ (infinite representable truths) and L₃ (logical primitives) directly
- **AI agents** operate derivatively on human-provided inputs, policies, and approvals

### ECAE Implications for Agents

| Aspect | Expert (Human) | AI Agent |
|--------|----------------|----------|
| Policy definition | Creates, modifies | Enforces, reports violations |
| Knowledge authority | Originates, validates | Derives, cites, flags uncertainty |
| Decision making | Approves, overrides | Recommends, executes with approval |
| Accountability | Responsible | Traceable (auditable) |

---

## Agent Classification: Passive vs Active

### Passive Agents (Tier 0-1)

**Characteristics:**
- Read-only access to systems
- Cannot modify state outside their evidence logs
- Full autonomy within observation scope
- No RBAC restrictions on each other (all can observe)

**Capabilities:**
- Query metrics, logs, configs
- Aggregate and summarize data
- Generate reports and recommendations
- Create evidence records
- Trigger alerts (notification only, not remediation)

**Examples:**
- HealthMonitor (observes metrics, flags anomalies)
- SessionCurator (reads session history, summarizes)
- GitWatcher (monitors repos, reports changes)
- BackupVerifier (checks backup integrity)
- TaskDigest (summarizes pending tasks)

**Autonomy Level:** HIGH within observation scope
- Can run on schedule without approval
- Can query any system they have connectors for
- Can store evidence and generate reports
- Cannot modify anything they observe

### Active Agents (Tier 2-3)

**Characteristics:**
- Can modify system state
- Require explicit authorization
- RBAC-controlled access to tools
- May only be invoked by:
  1. Human approval
  2. Passive agent escalation (with approval gate)
  3. Pre-approved automation policies

**Capabilities:**
- Restart services
- Scale resources
- Modify configurations
- Create/merge PRs
- Execute remediation runbooks

**Examples:**
- Executor (runs approved actions)
- ChangeDeployer (implements approved changes)
- RemediationAgent (executes runbook steps)
- AutoScaler (adjusts resources within bounds)

**Autonomy Level:** CONSTRAINED
- Actions require approval or pre-authorization
- Bounded by RBAC policies
- All actions logged with justification

---

## RBAC Model

### Role Hierarchy

```
┌─────────────────────────────────────────────────────────────┐
│                     Expert (Human)                          │
│  - Full authority over policy                               │
│  - Can invoke any agent                                     │
│  - Approves active agent actions                            │
└─────────────────────────┬───────────────────────────────────┘
                          │ delegates to
          ┌───────────────┴───────────────┐
          │                               │
          ▼                               ▼
┌─────────────────┐             ┌─────────────────┐
│ Passive Agents  │             │ Active Agents   │
│                 │             │                 │
│ - Read-only     │────────────▶│ - State-change  │
│ - Full autonomy │  escalates  │ - RBAC gated    │
│ - No RBAC gate  │  with       │ - Approval req  │
│                 │  evidence   │                 │
└─────────────────┘             └─────────────────┘
```

### Access Control Definitions

```python
from enum import Enum
from dataclasses import dataclass
from typing import Optional

class AgentRole(Enum):
    PASSIVE = "passive"    # Read-only, autonomous observation
    ACTIVE = "active"      # State-changing, RBAC controlled

class ApprovalType(Enum):
    NONE = "none"                    # Passive agents, no approval needed
    PRE_AUTHORIZED = "pre-authorized"  # Policy allows within bounds
    HUMAN_REQUIRED = "human-required"  # Must have explicit approval
    ESCALATION = "escalation"        # Passive agent requested active

@dataclass
class Permission:
    """Single permission grant."""
    tool: str                        # Tool name
    scope: str                       # Resource scope (e.g., "service:nginx")
    approval_type: ApprovalType
    conditions: Optional[dict] = None  # Additional constraints

@dataclass
class RBACPolicy:
    """RBAC policy for an agent or agent class."""
    agent_name: str
    role: AgentRole
    permissions: list[Permission]
    can_escalate_to: list[str]       # Active agents this can invoke
    requires_approval_from: list[str]  # Who can approve escalations

class RBACEnforcer:
    """Enforces RBAC policies at tool invocation."""

    def __init__(self, policies: dict[str, RBACPolicy]):
        self.policies = policies
        self.pending_approvals: dict[str, dict] = {}

    def check_permission(
        self,
        agent_name: str,
        tool: str,
        scope: str,
        context: dict
    ) -> tuple[bool, str, Optional[str]]:
        """
        Check if agent can invoke tool on scope.

        Returns:
            (allowed, reason, approval_id if pending)
        """
        policy = self.policies.get(agent_name)
        if not policy:
            return False, "No policy defined for agent", None

        # Passive agents can read anything
        if policy.role == AgentRole.PASSIVE:
            if self._is_read_only_tool(tool):
                return True, "Passive agent read access", None
            else:
                return False, "Passive agents cannot use state-changing tools", None

        # Active agents need permission check
        for perm in policy.permissions:
            if perm.tool == tool and self._scope_matches(perm.scope, scope):
                if perm.approval_type == ApprovalType.PRE_AUTHORIZED:
                    if self._check_conditions(perm.conditions, context):
                        return True, "Pre-authorized", None
                elif perm.approval_type == ApprovalType.HUMAN_REQUIRED:
                    approval_id = self._request_approval(agent_name, tool, scope, context)
                    return False, "Awaiting human approval", approval_id

        return False, "No matching permission", None

    def _is_read_only_tool(self, tool: str) -> bool:
        """Check if tool is read-only."""
        read_tools = {
            "get_system_metrics", "get_service_status", "get_recent_logs",
            "get_git_changes", "get_uncommitted_changes", "get_scheduled_tasks",
            "query_external", "correlate_alerts"
        }
        return tool in read_tools

    def _scope_matches(self, policy_scope: str, request_scope: str) -> bool:
        """Check if request scope matches policy scope."""
        if policy_scope == "*":
            return True
        # Simple prefix matching: "service:nginx" matches "service:nginx:restart"
        return request_scope.startswith(policy_scope)

    def _check_conditions(self, conditions: Optional[dict], context: dict) -> bool:
        """Evaluate policy conditions against context."""
        if not conditions:
            return True
        # Example conditions: {"environment": "dev", "max_instances": 5}
        for key, value in conditions.items():
            if context.get(key) != value:
                return False
        return True

    def _request_approval(
        self,
        agent_name: str,
        tool: str,
        scope: str,
        context: dict
    ) -> str:
        """Create pending approval request."""
        import uuid
        approval_id = str(uuid.uuid4())[:8]
        self.pending_approvals[approval_id] = {
            "agent": agent_name,
            "tool": tool,
            "scope": scope,
            "context": context,
            "status": "pending"
        }
        return approval_id
```

---

## Escalation Flow

When a passive agent detects a condition requiring action:

```
┌────────────────┐
│ Passive Agent  │
│ (e.g., Health  │
│  Monitor)      │
└───────┬────────┘
        │ detects: "nginx down"
        ▼
┌────────────────┐
│ Create         │
│ Escalation     │
│ Request        │
└───────┬────────┘
        │ includes: evidence, severity, recommended action
        ▼
┌────────────────┐     ┌────────────────┐
│ Approval Gate  │────▶│ Notify Expert  │
│                │     │ (human)        │
└───────┬────────┘     └───────┬────────┘
        │                      │
        │◀─────────────────────┘
        │ approval with optional modifications
        ▼
┌────────────────┐
│ Active Agent   │
│ (e.g.,         │
│  Executor)     │
└───────┬────────┘
        │ executes: "systemctl restart nginx"
        ▼
┌────────────────┐
│ Evidence       │
│ Record         │
│ (linked)       │
└────────────────┘
```

### Escalation Request Schema

```python
@dataclass
class EscalationRequest:
    """Request from passive agent to invoke active agent."""
    request_id: str
    source_agent: str           # Passive agent making request
    source_evidence: str        # Evidence record ID that triggered this
    target_agent: str           # Active agent to invoke
    target_action: str          # Specific action requested
    severity: str               # critical | high | medium | low
    justification: str          # Why this action is needed
    recommended_params: dict    # Suggested parameters
    deadline: Optional[datetime]  # When action loses relevance
    status: str = "pending"     # pending | approved | denied | expired

    def to_notification(self) -> dict:
        """Format for human notification."""
        return {
            "subject": f"[{self.severity.upper()}] Escalation: {self.target_action}",
            "body": f"""
Passive agent '{self.source_agent}' requests action:

**Action:** {self.target_action}
**Target Agent:** {self.target_agent}
**Severity:** {self.severity}

**Justification:**
{self.justification}

**Evidence:** {self.source_evidence}

**Recommended Parameters:**
{self.recommended_params}

Reply APPROVE or DENY (with optional modifications).
            """,
            "request_id": self.request_id
        }
```

---

## Pre-Authorization Policies

Experts can define policies that allow active agents to act without per-action approval:

```yaml
# config/rbac-policies.yaml

policies:
  auto-restart:
    description: "Auto-restart non-critical services if down < 5 min"
    active_agent: executor
    trigger_agent: health-monitor
    conditions:
      - service_criticality: low
      - downtime_minutes: "<5"
      - environment: ["dev", "staging"]  # NOT prod
    action: restart_service
    max_attempts: 3
    cooldown_minutes: 30

  auto-scale-dev:
    description: "Auto-scale dev resources within bounds"
    active_agent: auto-scaler
    trigger_agent: health-monitor
    conditions:
      - environment: dev
      - cpu_percent: ">80"
    action: scale_up
    bounds:
      min_instances: 1
      max_instances: 3
    cooldown_minutes: 15

  cleanup-logs:
    description: "Auto-cleanup logs older than 30 days"
    active_agent: maintenance-agent
    trigger_agent: backup-verifier
    conditions:
      - disk_percent: ">85"
      - log_age_days: ">30"
    action: cleanup_old_logs
    cooldown_minutes: 1440  # Once per day max
```

---

## Updated Agent Base Class

```python
class Agent(ABC):
    """Base class for all ThinxAI-Maestro agents."""

    def __init__(self, config: dict = None):
        self.config = config or {}
        self._tools = {}
        self._rbac: Optional[RBACEnforcer] = None

    @property
    @abstractmethod
    def name(self) -> str:
        pass

    @property
    @abstractmethod
    def role(self) -> AgentRole:
        """Whether this agent is passive or active."""
        pass

    @property
    @abstractmethod
    def description(self) -> str:
        pass

    @property
    @abstractmethod
    def required_tools(self) -> list[str]:
        pass

    def inject_rbac(self, rbac: RBACEnforcer):
        """Inject RBAC enforcer."""
        self._rbac = rbac

    def _call_tool(self, tool_name: str, scope: str = "*", **kwargs) -> Any:
        """
        Call tool with RBAC check.

        Raises:
            PermissionError if not authorized
            ValueError if awaiting approval
        """
        if self._rbac:
            allowed, reason, approval_id = self._rbac.check_permission(
                self.name, tool_name, scope, kwargs
            )
            if not allowed:
                if approval_id:
                    raise ValueError(f"Awaiting approval: {approval_id}")
                raise PermissionError(f"Not authorized: {reason}")

        if tool_name not in self._tools:
            raise KeyError(f"Tool '{tool_name}' not available")
        return self._tools[tool_name](**kwargs)

    def can_escalate_to(self, active_agent: str) -> bool:
        """Check if this passive agent can escalate to an active agent."""
        if self.role != AgentRole.PASSIVE:
            return False
        if not self._rbac:
            return False
        policy = self._rbac.policies.get(self.name)
        return active_agent in (policy.can_escalate_to if policy else [])

    def create_escalation(
        self,
        target_agent: str,
        action: str,
        severity: str,
        justification: str,
        evidence_id: str,
        params: dict = None
    ) -> EscalationRequest:
        """Create escalation request for human approval."""
        if not self.can_escalate_to(target_agent):
            raise PermissionError(f"Cannot escalate to {target_agent}")

        import uuid
        return EscalationRequest(
            request_id=str(uuid.uuid4())[:8],
            source_agent=self.name,
            source_evidence=evidence_id,
            target_agent=target_agent,
            target_action=action,
            severity=severity,
            justification=justification,
            recommended_params=params or {}
        )
```

---

## Summary

| Agent Type | Autonomy | RBAC | State Changes | Invocation |
|------------|----------|------|---------------|------------|
| Passive | Full (observation) | None | No | Schedule/adhoc |
| Active | Constrained | Yes | Yes | Human approval or pre-auth policy |

**ECAE Framing:**
- All policies, permissions, and pre-authorizations are **expert-curated**
- Agents execute derivatively within defined bounds
- Escalation ensures humans remain in the loop for consequential actions
- Evidence chain maintains full traceability and accountability
