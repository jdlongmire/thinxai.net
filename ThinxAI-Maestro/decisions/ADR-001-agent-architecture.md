# ADR-001: Agent Architecture Pattern

**Status:** Accepted
**Date:** 2026-02-07
**Deciders:** JD Longmire, Claude Code

## Context

ThinxAI-Maestro needs a consistent pattern for building agents that can:
1. Be scheduled or invoked ad hoc
2. Query external systems through connectors
3. Produce auditable evidence
4. Operate at different privilege levels

## Decision

Adopt a **capability-based agent pattern** with:

1. **Single Agent Interface** - All agents implement the same base contract
2. **Tool Injection** - Agents declare required tools; runner injects implementations
3. **Evidence-First Output** - All agents return structured Evidence objects
4. **Connector Abstraction** - External systems accessed through typed connectors

### Key Design Choices

**Why capability-based, not role-based?**
- Agents are defined by what they can do, not when they run
- Same agent works for scheduled and ad hoc invocation
- Enables agent composition (one agent calls another)

**Why tool injection?**
- Agents are testable (mock tools in tests)
- Tools can be swapped without changing agents
- Privilege enforcement happens at injection time

**Why structured Evidence?**
- Every conclusion traceable to source data
- Consistent format for storage and query
- Enables evidence chain across agents

## Consequences

### Positive
- Consistent development pattern across all agents
- Clear separation of concerns (agent logic vs tool implementation)
- Built-in auditability through Evidence schema
- Agents composable and reusable

### Negative
- More boilerplate than ad hoc scripting
- Learning curve for new agent development
- Evidence storage requires disk space

### Neutral
- Requires registry pattern for agent discovery
- Needs scheduler component for timed execution

## Alternatives Considered

1. **Simple function-based agents**
   - Rejected: No consistent evidence trail, hard to test

2. **Microservices per agent**
   - Rejected: Overkill for single-operator environment

3. **Plugin architecture**
   - Rejected: Similar complexity, less Python-native

## Related

- ADR-002: Connector pattern (pending)
- ADR-003: Evidence storage (pending)
- Design: `design/agent-architecture.md`
