# ThinxAI-Maestro

**Location:** [thinxai-maestro/](.)
**Focus:** Agentic IT I&O orchestration platform with tool-augmented LLM coordination

The name "**Maestro**" reflects the coordinator role: orchestrating agents, connectors, and tools into coherent operational workflows while leaving auditable evidence trails.

## Purpose

Developing ThinxAI-Maestro as an agentic IT Infrastructure & Operations orchestration system where:
- The LLM acts as coordinator (not knowledge store)
- Tools provide controlled, auditable access to systems
- Every action is grounded in authoritative systems of record
- Evidence trails are mandatory for all conclusions and actions

## Development Principles

From the architectural discussion (2026-02-07):

1. **Grounded in Reality** - Agent queries systems, acts through them, leaves a trail
2. **Evidence-Based** - No action without citation (ticket, metric, log, config state)
3. **Outcome-Driven Tools** - Define tools by outcomes, not by APIs
4. **Least Privilege** - Read-only → Suggest → Execute-with-approval → Autonomous
5. **Separation of Concerns** - Planner, Investigator, Executor, Verifier, Recorder
6. **Traceability First** - Every conclusion backed by evidence objects

## Agent Portfolio

### Schedule-Capable Agents

| Agent | Purpose | Scheduled | Ad Hoc |
|-------|---------|-----------|--------|
| HealthMonitor | System metrics, anomaly detection | ✓ | ✓ |
| SessionCurator | Archive logs, context handoff | ✓ | ✓ |
| GitWatcher | Uncommitted changes, sync status | ✓ | ✓ |
| BackupVerifier | Confirm backups, test restore | ✓ | ✓ |
| TaskDigest | Compile pending tasks | ✓ | ✓ |
| IncidentInvestigator | Logs, metrics → hypothesis | ✓ | ✓ |
| ReportGenerator | Template + data → document | | ✓ |
| DiagramRenderer | Specification → PNG/SVG | | ✓ |
| ChangePrepper | Risk assessment, PR drafting | | ✓ |
| SystemConnector | Interface with external tools | ✓ | ✓ |

### SystemConnector - External Tool Integration

Provides unified interface to monitoring/management platforms:
- SolarWinds, Prometheus, Grafana, PRTG, Zabbix
- Datadog, ServiceNow, Local system tools
- Normalizes responses for cross-platform correlation

## ECAE Governance (Expert-Curated, AI-Enabled)

Aligned with the AIDK framework:

| Role | Expert (Human) | AI Agent |
|------|----------------|----------|
| **Policy** | Creates, modifies | Enforces, reports |
| **Knowledge** | Originates, validates | Derives, cites, flags |
| **Decisions** | Approves, overrides | Recommends, executes |
| **Accountability** | Responsible | Traceable |

### Agent Classification

| Type | Autonomy | RBAC Required | State Changes |
|------|----------|---------------|---------------|
| **Passive** | Full (observation) | No | No |
| **Active** | Constrained | Yes | Yes |

Passive agents observe freely; active agents require RBAC authorization and escalate through approval gates.

## Web UI with Guardrail Feedback

A web-based configuration and operations interface featuring:

- **Dashboard** - Real-time overview with inline chat widget
- **Agents** - Configuration, monitoring, scheduling, RBAC
- **Escalations** - Approval queue with evidence preview
- **Knowledge** - Tiered RAG management (local → curated → internet)
- **Chat** - Full-page NLP interface with conversation history
- **Settings** - System config and RBAC policy editor

### Risk-Aware Approval Flow

Every state-modifying action goes through guardrail feedback:

| Risk Level | Color | Acknowledgment |
|------------|-------|----------------|
| Low | Green | Click to approve |
| Medium | Yellow | Checkbox confirmation |
| High | Orange | Type confirmation phrase |
| Critical | Red | MFA + manager approval |

The operator always sees: **"Do you understand and approve the risk?"** with blast radius, rollback info, and evidence links.

## Directory Structure

```
thinxai-maestro/
├── README.md                    # This file
├── ARCHITECTURE.md              # System design decisions
├── TRACEABILITY.md              # Decision log with evidence
├── design/
│   ├── agent-architecture.md    # Agent base contract, patterns
│   ├── agent-roles.md           # ECAE governance, passive/active, RBAC
│   ├── connector-interface.md   # SystemConnector design
│   ├── evidence-schema.md       # Evidence output format
│   ├── rag-architecture.md      # Tiered knowledge retrieval
│   └── web-ui.md                # Web interface with guardrails
├── implementation/
│   ├── phases/                  # Phase-by-phase implementation
│   └── agents/                  # Agent implementation notes
├── decisions/
│   └── ADR-*.md                 # Architecture Decision Records
└── references/
    ├── conversations/           # Key discussion captures
    └── frameworks/              # Governance framework guidance
        └── HCAE-framework.md    # Human-Curated, AI-Enabled
```

## Workflow

1. **Design** - Capture architecture decisions in `design/`
2. **Decide** - Log major decisions as ADRs in `decisions/`
3. **Implement** - Track implementation in `implementation/`
4. **Trace** - Update TRACEABILITY.md with evidence links
5. **Deploy** - Move working code to thinxai-web or thinxai-core repos

## Development Phases

### Phase 1: Read-Only Incident Copilot
- Tools: metrics, logs, deploy history, notes
- Output: evidence-backed triage summary

### Phase 2: Suggest Mode for Changes
- Tools: Git PR creation, IaC plan, policy checks
- Output: PRs and change plans, no execution

### Phase 3: Limited Execute-with-Approval
- Tools: bounded automations (restart, scale within limits)
- Output: closed-loop remediation with verification

## Traceability Requirements

Every implementation must include:
- Ticket/issue IDs and timestamps
- Metric names, queries, returned data
- Log queries and representative lines
- Config item identifiers and state
- Diffs, PR links, change records
- Command outputs (captured, not paraphrased)

## Design Documents

| Document | Purpose |
|----------|---------|
| [agent-architecture.md](design/agent-architecture.md) | Base agent contract, lifecycle, patterns |
| [agent-roles.md](design/agent-roles.md) | ECAE governance, passive/active classification, RBAC |
| [connector-interface.md](design/connector-interface.md) | SystemConnector design, platform adapters |
| [evidence-schema.md](design/evidence-schema.md) | Evidence output format, validation |
| [rag-architecture.md](design/rag-architecture.md) | Tiered knowledge retrieval (local → curated → internet) |
| [web-ui.md](design/web-ui.md) | Web interface, chatbot, guardrail feedback |

## Framework Guidance

| Document | Source |
|----------|--------|
| [HCAE Framework](references/frameworks/HCAE-framework.md) | [Zenodo DOI: 10.5281/zenodo.18368697](https://zenodo.org/records/18368697) |

ThinxAI-Maestro operates at **ECAE (Expert-Curated, AI-Enabled)** level—the tier appropriate for high-consequence IT operations work.

## Related

- [AI Research](../ai-research/) - AIDK framework informing design
- [Logic Realism](../logic-realism/) - L₃ epistemic grounding
- [ThinxAI Web](../../thinxai-web/) - Implementation target

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
