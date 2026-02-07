# ThinxAI-Maestro - Traceability Log

This document tracks all decisions, implementations, and their evidence trails.

## Format

Each entry follows this structure:

```
## [YYYY-MM-DD] Decision/Action Title

**Type:** Design | Implementation | Decision | Discussion
**Status:** Proposed | In Progress | Completed | Superseded
**Agent:** Agent_YYYYMMDD_HHMM (if applicable)

### Context
What prompted this?

### Evidence
- Source: [link or reference]
- Discussion: [conversation reference]
- Related: [linked items]

### Decision/Outcome
What was decided or done?

### Trace
- Files created/modified:
- Commits:
- Issues:
```

---

## 2026-02-07 | Initial Architecture Discussion

**Type:** Discussion
**Status:** Captured
**Agent:** Claude Code Session

### Context
JD initiated discussion on building ThinxAI-Maestro as an agentic IT I&O orchestration system with tool-augmented LLM coordination.

### Evidence
- Source: VS Code Claude conversation 2026-02-07
- Key insight: "The model should not 'know' infrastructure. It should query it, act through it, and leave a trail."

### Decision/Outcome
Established core principles:
1. LLM as coordinator, not knowledge store
2. Evidence-based actions only
3. Outcome-driven tool design
4. Tiered privilege levels (read-only → suggest → execute-with-approval → autonomous)
5. Separation: Planner, Investigator, Executor, Verifier, Recorder

### Trace
- Files created: `research-programs/thinxai-maestro/README.md`
- Files created: `research-programs/thinxai-maestro/TRACEABILITY.md`

---

## 2026-02-07 | Agent Portfolio Definition

**Type:** Design
**Status:** Proposed

### Context
Defined initial set of schedule-capable agents and SystemConnector pattern.

### Evidence
- Source: VS Code Claude conversation 2026-02-07
- Pattern: All agents can be scheduled OR invoked ad hoc

### Decision/Outcome
10 initial agents defined:
- HealthMonitor, SessionCurator, GitWatcher, BackupVerifier, TaskDigest
- IncidentInvestigator, ReportGenerator, DiagramRenderer, ChangePrepper
- SystemConnector (external tool interface)

SystemConnector abstracts external APIs:
- SolarWinds, Prometheus, Grafana, PRTG, Zabbix, Datadog, ServiceNow
- Provides normalized response format for cross-platform correlation

### Trace
- Design captured: `design/agent-architecture.md` (pending)
- Design captured: `design/connector-interface.md` (pending)

---

## 2026-02-07 | Project Renamed to ThinxAI-Maestro

**Type:** Decision
**Status:** Completed
**Agent:** Claude Code Session

### Context
Project needed a distinct identity reflecting its orchestration role.

### Evidence
- Source: VS Code Claude conversation 2026-02-07
- Name rationale: "Maestro" reflects the coordinator role - orchestrating agents, connectors, and tools into coherent operational workflows

### Decision/Outcome
- Renamed from "ThinxAI Infrastructure" to "ThinxAI-Maestro"
- Updated all documentation to reflect new branding
- Folder renamed from `thinxai-infrastructure/` to `thinxai-maestro/`

### Trace
- Folder renamed: `research-programs/thinxai-infrastructure/` → `research-programs/thinxai-maestro/`
- Files updated: README.md, ARCHITECTURE.md, TRACEABILITY.md, ADR-001, phase-1-read-only.md
- Parent updated: `research-programs/README.md`

---

## 2026-02-07 | RAG Architecture for Historical Data

**Type:** Design
**Status:** Proposed
**Agent:** Agent_20260207_0720

### Context
Agents need institutional memory - not just current state, but historical patterns for comparison. RAG enables agents to:
- Find similar past incidents
- Compare metrics against baselines
- Retrieve relevant runbooks
- Track what changed recently

### Evidence
- Source: VS Code Claude conversation 2026-02-07
- Key insight: "RAG gives agents institutional memory - they don't just react to current state, they compare against historical patterns"

### Decision/Outcome
1. **KnowledgeStore interface** - Collection-aware vector store abstraction
2. **Six knowledge collections:**
   - incident-history, metric-baselines, runbooks
   - change-log, alert-patterns, agent-evidence
3. **Storage strategy:**
   - Start: ChromaDB (local, simple)
   - Target: Qdrant (production scale)
4. **Embeddings:** Local models (all-MiniLM-L6-v2), no API dependency
5. **Ingestion pipelines:** from agent evidence, monitoring tools, git history

### Trace
- Files created: `design/rag-architecture.md`
- Design patterns: Collection separation, baseline stats, ingestion pipelines
- Dependencies: chromadb, sentence-transformers

---

## 2026-02-07 | Tiered RAG with Ingestion Interface

**Type:** Design
**Status:** Proposed
**Agent:** Agent_20260207_0720

### Context
Initial RAG design focused on internal collections. Expanded to include:
- Tiered architecture with trust levels
- External specialized knowledge bases (CVE, vendor docs, RFCs)
- Internet search as supplemental source
- Unified ingestion interface for all sources

### Evidence
- Source: VS Code Claude conversation 2026-02-07
- Key insight: "Internal RAG (RAGs by category?) with an ingestion interface and also with access to the Internet and other specialized knowledge bases"

### Decision/Outcome
1. **Three-tier architecture:**
   - Tier 1 (Internal): Operations, runbooks, evidence - 100% trust
   - Tier 2 (Specialized): CVE/NVD, vendor docs, RFCs - 90-95% trust
   - Tier 3 (Internet): Web search, forums, blogs - 50-80% trust

2. **Category-based organization:**
   - Internal: operations/*, runbooks/*, evidence/*
   - Specialized: security/*, vendor/*, standards/*
   - Different retention, embedding, update patterns per category

3. **Unified IngestionManager:**
   - Push methods: ingest_document, ingest_batch, ingest_from_evidence
   - Pull methods: register_source, scheduled pulls
   - File watch: watch_directory for runbooks/configs
   - Webhooks: external systems push via HTTP
   - Streams: Kafka/Redis for real-time

4. **Source connectors pattern:**
   - KnowledgeSource ABC for external sources
   - NVDSource, MSDocsSource, WebSearchSource implementations
   - Scheduled sync with cron expressions

5. **Trust scores on results:**
   - Every RetrievalResult includes tier, source, trust_score
   - Agents weight by reliability: relevance × trust

6. **Query routing:**
   - Always query Tier 1 first
   - Tier 2 if categories specified or insufficient internal coverage
   - Tier 3 only with explicit opt-in (`include_internet: True`)

### Trace
- Files updated: `design/rag-architecture.md` (major rewrite)
- New patterns: IngestionManager, KnowledgeSource ABC, tiered stores
- Dependencies added: httpx, beautifulsoup4, pyyaml, schedule, brave-search

---

## 2026-02-07 | Passive/Active Agent Model with ECAE and RBAC

**Type:** Design
**Status:** Proposed
**Agent:** Agent_20260207_0720

### Context
Need clear governance model for agent autonomy. Key requirements:
- Observation agents should run autonomously without blocking
- State-changing agents need approval controls
- Human expertise must remain authoritative (AIDK framework alignment)
- Traceability through evidence chains

### Evidence
- Source: VS Code Claude conversation 2026-02-07
- Key insight: "Passive agents that can have autonomy and RBAC controlled access to active agents with Expert-Curated, AI-Enabled (ECAE) framing"
- AIDK connection: Agents as derivative actors (cannot originate knowledge/policy)

### Decision/Outcome
1. **Two agent classifications:**
   - **Passive agents:** Full autonomy for observation, read-only tools, no RBAC gates
   - **Active agents:** State-changing, RBAC controlled, require approval or pre-auth

2. **ECAE (Expert-Curated, AI-Enabled) framing:**
   - Humans originate policy, validate knowledge, approve actions
   - Agents derive, enforce, execute, report within human-defined bounds
   - Maps directly to AIDK origination/derivation distinction

3. **RBAC model:**
   - AgentRole enum: PASSIVE, ACTIVE
   - Permission grants with tool, scope, approval_type, conditions
   - RBACEnforcer checks all active agent tool calls
   - Passive agents bypass RBAC for read tools

4. **Escalation flow:**
   - Passive agents detect conditions requiring action
   - Create EscalationRequest with evidence, severity, justification
   - Human approval gate (or pre-authorization policy match)
   - Active agent executes, records evidence linked to escalation

5. **Pre-authorization policies:**
   - YAML-defined policies for bounded automation
   - Conditions, bounds, cooldowns, max attempts
   - Active agents can act autonomously within policy

### Trace
- Files created: `design/agent-roles.md` (full ECAE/RBAC design)
- Files updated: `ARCHITECTURE.md` (agent classification, ECAE principle, RBAC structure)
- New patterns: AgentRole, RBACEnforcer, EscalationRequest, pre-auth policies

---

## 2026-02-07 | Web UI with Chatbot Interface

**Type:** Design
**Status:** Proposed
**Agent:** Agent_20260207_0720

### Context
ThinxAI-Maestro needs a human touchpoint for configuration, operations, and natural language interaction. Key requirements:
- Configuration management for agents, policies, knowledge sources
- Operations dashboard with real-time monitoring
- Escalation approval workflow
- AI-guided NLP chatbot for natural language operations

### Evidence
- Source: VS Code Claude conversation 2026-02-07
- Key insight: "All with a web based front end for configuration and operations that includes a chat bot interface for AI guided NLP capabilities opportunities"

### Decision/Outcome
1. **Six main pages:**
   - Dashboard: Real-time overview, activity stream, inline chat widget
   - Agents: Configuration, monitoring, schedule management
   - Escalations: Approval queue with evidence preview
   - Knowledge: Tiered RAG management, ingestion config
   - Chat: Full-page NLP interface with conversation history
   - Settings: System config, RBAC policy editor

2. **Technical stack:**
   - Frontend: Vue 3 + TailwindCSS + Pinia
   - Backend: FastAPI + PostgreSQL + Redis
   - Real-time: WebSocket for agent updates and chat streaming
   - Auth: OAuth2 + JWT (enterprise SSO ready)

3. **Chatbot capabilities:**
   - Intent classification (status, lookup, search, control, config)
   - Entity extraction (agents, services, dates)
   - Context resolution for conversational flow
   - Rich responses: evidence cards, quick actions, suggestions

4. **ECAE enforcement in chat:**
   - Chatbot cannot execute active actions without explicit approval
   - All state-modifying actions logged with user + timestamp
   - Tier 3 (internet) access requires user permission
   - RBAC middleware checks all chat actions

### Trace
- Files created: `design/web-ui.md`
- Architecture patterns: Chat session, NLP pipeline, RBAC middleware
- Dependencies: vue, fastapi, pinia, tailwindcss, socket.io

---

## Template for Future Entries

Copy this for new entries:

```markdown
## YYYY-MM-DD | Title

**Type:** Design | Implementation | Decision | Discussion
**Status:** Proposed | In Progress | Completed | Superseded
**Agent:** Agent_YYYYMMDD_HHMM

### Context
[What prompted this?]

### Evidence
- Source:
- Discussion:
- Related:

### Decision/Outcome
[What was decided or done?]

### Trace
- Files created/modified:
- Commits:
- Issues:
```
