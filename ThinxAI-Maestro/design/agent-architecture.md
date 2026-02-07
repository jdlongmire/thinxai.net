# Agent Architecture Design

## Overview

All ThinxAI agents share a common contract while specializing for specific outcomes.

## Base Agent Contract

```python
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from datetime import datetime
from typing import Any, Optional
from enum import Enum

class TriggerType(Enum):
    SCHEDULE = "schedule"
    ADHOC = "adhoc"
    AGENT = "agent"

@dataclass
class Evidence:
    """Immutable record of agent execution."""
    agent: str
    run_id: str
    triggered_by: TriggerType
    triggering_agent: Optional[str] = None  # If triggered by another agent
    timestamp: datetime = field(default_factory=datetime.utcnow)

    # What was observed
    evidence: dict[str, Any] = field(default_factory=dict)

    # What we concluded
    conclusions: list[str] = field(default_factory=list)

    # What we did
    actions_taken: list[dict] = field(default_factory=list)

    # What we recommend
    recommendations: list[str] = field(default_factory=list)

    # What should happen next
    next_steps: list[str] = field(default_factory=list)

    def to_dict(self) -> dict:
        return {
            "agent": self.agent,
            "run_id": self.run_id,
            "triggered_by": self.triggered_by.value,
            "triggering_agent": self.triggering_agent,
            "timestamp": self.timestamp.isoformat(),
            "evidence": self.evidence,
            "conclusions": self.conclusions,
            "actions_taken": self.actions_taken,
            "recommendations": self.recommendations,
            "next_steps": self.next_steps
        }

class Agent(ABC):
    """Base class for all ThinxAI agents."""

    def __init__(self, config: dict = None):
        self.config = config or {}
        self._tools = {}

    @property
    @abstractmethod
    def name(self) -> str:
        """Unique agent identifier."""
        pass

    @property
    @abstractmethod
    def description(self) -> str:
        """What this agent does."""
        pass

    @property
    @abstractmethod
    def required_tools(self) -> list[str]:
        """Tools this agent needs to function."""
        pass

    @property
    def optional_tools(self) -> list[str]:
        """Tools that enhance but aren't required."""
        return []

    def inject_tools(self, tools: dict):
        """Inject tool implementations."""
        self._tools = tools

    @abstractmethod
    def run(self, context: dict) -> Evidence:
        """
        Execute agent and return structured evidence.

        Args:
            context: Execution context (varies by agent)

        Returns:
            Evidence record with all observations and actions
        """
        pass

    def can_schedule(self) -> bool:
        """Whether this agent supports scheduled runs."""
        return True

    def schedule_config(self) -> Optional[dict]:
        """
        Default schedule configuration.

        Returns:
            {"cron": "*/15 * * * *", "enabled": True} or None
        """
        return None

    def validate_context(self, context: dict) -> tuple[bool, str]:
        """
        Validate context before execution.

        Returns:
            (is_valid, error_message)
        """
        return True, ""

    def _generate_run_id(self) -> str:
        """Generate unique run ID."""
        now = datetime.utcnow()
        return f"{self.name}_{now.strftime('%Y%m%d_%H%M%S')}"

    def _call_tool(self, tool_name: str, **kwargs) -> Any:
        """
        Call an injected tool.

        Raises:
            KeyError if tool not available
        """
        if tool_name not in self._tools:
            raise KeyError(f"Tool '{tool_name}' not available")
        return self._tools[tool_name](**kwargs)
```

## Agent Registry

```python
from typing import Type

class AgentRegistry:
    """Discovers and manages available agents."""

    _agents: dict[str, Type[Agent]] = {}

    @classmethod
    def register(cls, agent_class: Type[Agent]):
        """Register an agent class."""
        instance = agent_class()
        cls._agents[instance.name] = agent_class
        return agent_class

    @classmethod
    def get(cls, name: str) -> Type[Agent]:
        """Get agent class by name."""
        return cls._agents[name]

    @classmethod
    def list_agents(cls) -> list[dict]:
        """List all registered agents."""
        result = []
        for name, agent_class in cls._agents.items():
            instance = agent_class()
            result.append({
                "name": name,
                "description": instance.description,
                "can_schedule": instance.can_schedule(),
                "schedule": instance.schedule_config(),
                "required_tools": instance.required_tools
            })
        return result

    @classmethod
    def get_scheduled_agents(cls) -> list[dict]:
        """Get agents with schedule configurations."""
        return [a for a in cls.list_agents() if a["schedule"]]
```

## Example: HealthMonitor Agent

```python
@AgentRegistry.register
class HealthMonitor(Agent):

    @property
    def name(self) -> str:
        return "health-monitor"

    @property
    def description(self) -> str:
        return "Monitor system health metrics and detect anomalies"

    @property
    def required_tools(self) -> list[str]:
        return ["get_system_metrics", "get_service_status"]

    @property
    def optional_tools(self) -> list[str]:
        return ["send_alert", "create_task_note"]

    def schedule_config(self) -> dict:
        return {"cron": "*/15 * * * *", "enabled": True}

    def run(self, context: dict) -> Evidence:
        run_id = self._generate_run_id()

        # Gather evidence
        metrics = self._call_tool("get_system_metrics")
        services = {}
        for svc in context.get("services", ["ssh", "cron"]):
            services[svc] = self._call_tool("get_service_status", service_name=svc)

        # Analyze
        conclusions = []
        recommendations = []

        if metrics.get("cpu", 0) > 80:
            conclusions.append(f"High CPU usage: {metrics['cpu']}%")
            recommendations.append("Investigate CPU-intensive processes")

        if metrics.get("disk", 0) > 90:
            conclusions.append(f"Disk nearly full: {metrics['disk']}%")
            recommendations.append("Clean up disk space or expand volume")

        failed_services = [s for s, status in services.items() if status != "active"]
        if failed_services:
            conclusions.append(f"Services not running: {', '.join(failed_services)}")
            recommendations.append("Check service logs and restart if appropriate")

        status = "healthy" if not conclusions else "degraded"

        return Evidence(
            agent=self.name,
            run_id=run_id,
            triggered_by=TriggerType(context.get("triggered_by", "adhoc")),
            evidence={
                "metrics": metrics,
                "services": services,
                "status": status
            },
            conclusions=conclusions or ["All systems healthy"],
            actions_taken=[],
            recommendations=recommendations,
            next_steps=["Review in 15 minutes"] if conclusions else []
        )
```

## Tool Injection Pattern

```python
# At runtime, inject tools into agents
from tools import observability, notifications

def run_agent(agent_name: str, context: dict) -> Evidence:
    agent_class = AgentRegistry.get(agent_name)
    agent = agent_class()

    # Inject tools based on agent requirements
    tools = {}
    if "get_system_metrics" in agent.required_tools:
        tools["get_system_metrics"] = observability.get_system_metrics
    if "get_service_status" in agent.required_tools:
        tools["get_service_status"] = observability.get_service_status
    if "send_alert" in agent.optional_tools:
        tools["send_alert"] = notifications.send_alert

    agent.inject_tools(tools)

    # Validate and run
    is_valid, error = agent.validate_context(context)
    if not is_valid:
        raise ValueError(f"Invalid context: {error}")

    return agent.run(context)
```

## Next Steps

1. Implement `base.py` with Agent and Evidence classes
2. Implement HealthMonitor as first concrete agent
3. Build tool implementations in `tools/`
4. Create scheduler runner
