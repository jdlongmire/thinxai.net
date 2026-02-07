# Evidence Schema Design

## Purpose

Every agent action must be backed by traceable evidence. This schema defines the standard format for capturing, storing, and referencing evidence.

## Core Principle

> If it cannot cite what it saw (ticket, metric, log line, config state, change record), it should not act.

## Evidence Object Schema

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://thinxai.net/schemas/evidence.json",
  "title": "ThinxAI Evidence",
  "description": "Structured evidence from agent execution",
  "type": "object",
  "required": ["agent", "run_id", "triggered_by", "timestamp", "evidence"],
  "properties": {
    "agent": {
      "type": "string",
      "description": "Agent name that produced this evidence"
    },
    "run_id": {
      "type": "string",
      "pattern": "^[a-z-]+_[0-9]{8}_[0-9]{6}$",
      "description": "Unique run identifier: agent_YYYYMMDD_HHMMSS"
    },
    "triggered_by": {
      "type": "string",
      "enum": ["schedule", "adhoc", "agent"],
      "description": "What triggered this execution"
    },
    "triggering_agent": {
      "type": ["string", "null"],
      "description": "If triggered by another agent, its name"
    },
    "timestamp": {
      "type": "string",
      "format": "date-time",
      "description": "ISO 8601 timestamp of execution"
    },
    "duration_ms": {
      "type": "integer",
      "description": "Execution duration in milliseconds"
    },
    "evidence": {
      "$ref": "#/$defs/evidence_payload"
    },
    "conclusions": {
      "type": "array",
      "items": {"type": "string"},
      "description": "What we concluded from the evidence"
    },
    "actions_taken": {
      "type": "array",
      "items": {"$ref": "#/$defs/action_record"},
      "description": "Actions performed during execution"
    },
    "recommendations": {
      "type": "array",
      "items": {"type": "string"},
      "description": "Recommended next steps"
    },
    "next_steps": {
      "type": "array",
      "items": {"type": "string"},
      "description": "Pending follow-up items"
    }
  },
  "$defs": {
    "evidence_payload": {
      "type": "object",
      "description": "The actual evidence gathered",
      "properties": {
        "metrics": {"$ref": "#/$defs/metric_evidence"},
        "logs": {"$ref": "#/$defs/log_evidence"},
        "configs": {"$ref": "#/$defs/config_evidence"},
        "commands": {"$ref": "#/$defs/command_evidence"},
        "tickets": {"$ref": "#/$defs/ticket_evidence"},
        "changes": {"$ref": "#/$defs/change_evidence"}
      }
    },
    "metric_evidence": {
      "type": "object",
      "description": "Metrics observed",
      "additionalProperties": {
        "type": "object",
        "properties": {
          "source": {"type": "string"},
          "query": {"type": "string"},
          "value": {"type": ["number", "string"]},
          "unit": {"type": "string"},
          "timestamp": {"type": "string", "format": "date-time"},
          "threshold": {"type": "number"},
          "status": {"type": "string", "enum": ["normal", "warning", "critical"]}
        }
      }
    },
    "log_evidence": {
      "type": "array",
      "description": "Log entries observed",
      "items": {
        "type": "object",
        "required": ["source", "query", "entries"],
        "properties": {
          "source": {"type": "string"},
          "query": {"type": "string"},
          "window": {"type": "string"},
          "total_matches": {"type": "integer"},
          "entries": {
            "type": "array",
            "items": {
              "type": "object",
              "properties": {
                "timestamp": {"type": "string"},
                "level": {"type": "string"},
                "message": {"type": "string"},
                "metadata": {"type": "object"}
              }
            }
          }
        }
      }
    },
    "config_evidence": {
      "type": "object",
      "description": "Configuration state observed",
      "additionalProperties": {
        "type": "object",
        "properties": {
          "source": {"type": "string"},
          "path": {"type": "string"},
          "value": {},
          "last_modified": {"type": "string", "format": "date-time"},
          "version": {"type": "string"}
        }
      }
    },
    "command_evidence": {
      "type": "array",
      "description": "Commands executed and their outputs",
      "items": {
        "type": "object",
        "required": ["command", "exit_code", "stdout"],
        "properties": {
          "command": {"type": "string"},
          "exit_code": {"type": "integer"},
          "stdout": {"type": "string"},
          "stderr": {"type": "string"},
          "duration_ms": {"type": "integer"},
          "timestamp": {"type": "string", "format": "date-time"}
        }
      }
    },
    "ticket_evidence": {
      "type": "array",
      "description": "Tickets/issues referenced",
      "items": {
        "type": "object",
        "properties": {
          "system": {"type": "string"},
          "ticket_id": {"type": "string"},
          "url": {"type": "string", "format": "uri"},
          "status": {"type": "string"},
          "summary": {"type": "string"}
        }
      }
    },
    "change_evidence": {
      "type": "array",
      "description": "Changes observed or made",
      "items": {
        "type": "object",
        "properties": {
          "type": {"type": "string", "enum": ["git_commit", "config_change", "deploy", "pr"]},
          "id": {"type": "string"},
          "url": {"type": "string", "format": "uri"},
          "author": {"type": "string"},
          "timestamp": {"type": "string", "format": "date-time"},
          "summary": {"type": "string"},
          "diff": {"type": "string"}
        }
      }
    },
    "action_record": {
      "type": "object",
      "description": "Record of an action taken",
      "required": ["action", "target", "result"],
      "properties": {
        "action": {"type": "string"},
        "target": {"type": "string"},
        "params": {"type": "object"},
        "result": {"type": "string", "enum": ["success", "failure", "skipped"]},
        "message": {"type": "string"},
        "timestamp": {"type": "string", "format": "date-time"},
        "reversible": {"type": "boolean"},
        "rollback_command": {"type": "string"}
      }
    }
  }
}
```

## Example Evidence Objects

### Health Monitor Evidence

```json
{
  "agent": "health-monitor",
  "run_id": "health-monitor_20260207_143000",
  "triggered_by": "schedule",
  "timestamp": "2026-02-07T14:30:00Z",
  "duration_ms": 1523,
  "evidence": {
    "metrics": {
      "cpu": {
        "source": "local",
        "query": "psutil.cpu_percent()",
        "value": 45.2,
        "unit": "percent",
        "timestamp": "2026-02-07T14:30:00Z",
        "threshold": 80,
        "status": "normal"
      },
      "memory": {
        "source": "local",
        "query": "psutil.virtual_memory().percent",
        "value": 78.1,
        "unit": "percent",
        "timestamp": "2026-02-07T14:30:00Z",
        "threshold": 90,
        "status": "normal"
      },
      "disk": {
        "source": "local",
        "query": "psutil.disk_usage('/').percent",
        "value": 67.3,
        "unit": "percent",
        "timestamp": "2026-02-07T14:30:00Z",
        "threshold": 85,
        "status": "normal"
      }
    },
    "commands": [
      {
        "command": "systemctl is-active ssh",
        "exit_code": 0,
        "stdout": "active",
        "duration_ms": 45,
        "timestamp": "2026-02-07T14:30:00Z"
      },
      {
        "command": "systemctl is-active cron",
        "exit_code": 0,
        "stdout": "active",
        "duration_ms": 38,
        "timestamp": "2026-02-07T14:30:00Z"
      }
    ]
  },
  "conclusions": [
    "All systems healthy",
    "No services in failed state",
    "Resource usage within normal bounds"
  ],
  "actions_taken": [],
  "recommendations": [],
  "next_steps": []
}
```

### Incident Investigator Evidence

```json
{
  "agent": "incident-investigator",
  "run_id": "incident-investigator_20260207_153045",
  "triggered_by": "adhoc",
  "timestamp": "2026-02-07T15:30:45Z",
  "duration_ms": 8234,
  "evidence": {
    "metrics": {
      "api_latency_p99": {
        "source": "prometheus",
        "query": "histogram_quantile(0.99, sum(rate(http_request_duration_seconds_bucket[5m])) by (le))",
        "value": 2.4,
        "unit": "seconds",
        "timestamp": "2026-02-07T15:30:00Z",
        "threshold": 1.0,
        "status": "critical"
      }
    },
    "logs": [
      {
        "source": "local",
        "query": "journalctl -u api-server --since '30 min ago' | grep -i error",
        "window": "30m",
        "total_matches": 47,
        "entries": [
          {
            "timestamp": "2026-02-07T15:28:12Z",
            "level": "ERROR",
            "message": "Database connection pool exhausted",
            "metadata": {"pool_size": 20, "waiting": 35}
          },
          {
            "timestamp": "2026-02-07T15:28:45Z",
            "level": "ERROR",
            "message": "Query timeout after 30s",
            "metadata": {"query_id": "abc123"}
          }
        ]
      }
    ],
    "changes": [
      {
        "type": "git_commit",
        "id": "a1b2c3d4",
        "url": "https://github.com/org/repo/commit/a1b2c3d4",
        "author": "developer@example.com",
        "timestamp": "2026-02-07T14:45:00Z",
        "summary": "Increase query complexity for new feature"
      }
    ]
  },
  "conclusions": [
    "API latency spike started ~15:00",
    "Database connection pool exhausted (20/20 connections in use)",
    "47 error logs in last 30 minutes",
    "Recent commit increased query complexity",
    "Root cause: Database cannot handle increased query load"
  ],
  "actions_taken": [],
  "recommendations": [
    "Increase database connection pool size",
    "Review and optimize queries from commit a1b2c3d4",
    "Consider adding query caching"
  ],
  "next_steps": [
    "Get approval to increase pool size",
    "Create ticket for query optimization"
  ]
}
```

## Storage Structure

```
evidence/
├── 2026-02/
│   ├── 07/
│   │   ├── health-monitor_143000.json
│   │   ├── health-monitor_144500.json
│   │   ├── incident-investigator_153045.json
│   │   └── index.json  # Daily summary
│   └── index.json      # Monthly summary
└── index.json          # Overall index
```

### Index File Format

```json
{
  "period": "2026-02-07",
  "agents": {
    "health-monitor": {
      "runs": 96,
      "conclusions": {"healthy": 94, "degraded": 2}
    },
    "incident-investigator": {
      "runs": 1,
      "conclusions": {"resolved": 0, "in_progress": 1}
    }
  },
  "alerts_generated": 2,
  "actions_taken": 0
}
```

## Evidence Linking

Evidence can reference other evidence:

```json
{
  "related_evidence": [
    {
      "run_id": "health-monitor_143000",
      "relationship": "triggered_by",
      "reason": "Anomaly detected in metrics"
    }
  ]
}
```

## Retention Policy

| Age | Storage | Format |
|-----|---------|--------|
| < 7 days | Full JSON | All details |
| 7-30 days | Compressed JSON | All details |
| 30-90 days | Summary + key evidence | Reduced logs |
| > 90 days | Index only | Counts and summaries |

## Querying Evidence

Python interface for evidence queries:

```python
from evidence import EvidenceStore

store = EvidenceStore("evidence/")

# Find all evidence for a time range
results = store.query(
    start="2026-02-07T00:00:00Z",
    end="2026-02-07T23:59:59Z",
    agent="health-monitor"
)

# Find evidence with specific conclusions
results = store.query(
    conclusion_contains="database",
    start="2026-02-01"
)

# Get related evidence chain
chain = store.get_evidence_chain("incident-investigator_153045")
```
