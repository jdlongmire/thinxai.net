# Phase 1: Read-Only Incident Copilot

**Status:** Not Started
**Target:** First working agent with evidence trail

## Objective

Build a read-only incident copilot that can:
1. Query system metrics (CPU, memory, disk)
2. Read service status (systemctl)
3. Search logs (journalctl)
4. Produce structured evidence

## Deliverables

### 1. Agent Base Class
- [ ] `agents/base.py` - Agent and Evidence classes
- [ ] `agents/registry.py` - Agent registration and discovery

### 2. Core Tools
- [ ] `tools/observability.py`
  - [ ] `get_system_metrics()` - psutil wrapper
  - [ ] `get_service_status(service)` - systemctl wrapper
  - [ ] `get_recent_logs(service, window, filter)` - journalctl wrapper

### 3. Health Monitor Agent
- [ ] `agents/health_monitor.py`
  - [ ] Queries metrics
  - [ ] Checks key services
  - [ ] Produces Evidence with conclusions

### 4. Evidence Storage
- [ ] `evidence/store.py` - Write and query evidence
- [ ] Evidence directory structure

### 5. Runner
- [ ] `scheduler/runner.py` - Execute agent with tool injection
- [ ] CLI entry point for ad hoc execution

## Success Criteria

1. Can run `maestro health-monitor` from command line
2. Produces valid Evidence JSON
3. Evidence stored in `evidence/YYYY-MM/DD/`
4. Works without external dependencies (local only)

## Non-Goals for Phase 1

- No scheduling (manual execution only)
- No external connectors (local system only)
- No action execution (read-only)
- No web interface

## Implementation Notes

### File Locations

Implementation goes in:
- `thinxai-web/agents/` (for web integration)
- OR `thinxai-core/agents/` (if standalone package)

Design documents stay in:
- `research-programs/thinxai-maestro/`

### Testing

```bash
# Manual test
python -m agents.health_monitor

# Verify evidence
cat evidence/2026-02/07/health-monitor_*.json | jq .
```

## Progress Log

_Track implementation progress here_

| Date | Item | Status | Notes |
|------|------|--------|-------|
| | | | |
