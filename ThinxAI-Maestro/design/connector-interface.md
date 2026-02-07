# SystemConnector Interface Design

## Overview

SystemConnector provides a unified interface for querying external monitoring and management platforms. It abstracts vendor-specific APIs behind a common interface.

## Connector Base Interface

```python
from abc import ABC, abstractmethod
from dataclasses import dataclass
from datetime import datetime
from typing import Any, Optional
from enum import Enum

class ConnectorCapability(Enum):
    METRICS = "metrics"
    ALERTS = "alerts"
    LOGS = "logs"
    INVENTORY = "inventory"
    TOPOLOGY = "topology"
    CHANGES = "changes"
    TICKETS = "tickets"

@dataclass
class NodeStatus:
    """Normalized node/host status."""
    node_id: str
    name: str
    status: str  # "up", "down", "degraded", "unknown"
    last_seen: datetime
    metrics: dict[str, float] = None
    alerts: list[dict] = None
    metadata: dict = None

@dataclass
class MetricData:
    """Normalized metric response."""
    node_id: str
    metrics: dict[str, list[tuple[datetime, float]]]  # metric_name -> [(time, value)]
    window: str
    resolution: str

@dataclass
class Alert:
    """Normalized alert."""
    alert_id: str
    source: str  # connector name
    severity: str  # "critical", "warning", "info"
    title: str
    description: str
    node_id: Optional[str]
    timestamp: datetime
    status: str  # "active", "acknowledged", "resolved"
    metadata: dict = None

@dataclass
class Asset:
    """Normalized asset/inventory item."""
    asset_id: str
    source: str
    name: str
    asset_type: str  # "server", "network", "application", etc.
    status: str
    metadata: dict = None

@dataclass
class ActionResult:
    """Result of an action executed through connector."""
    success: bool
    action: str
    target: str
    message: str
    details: dict = None


class Connector(ABC):
    """Base interface for external system connectors."""

    def __init__(self, config: dict):
        self.config = config
        self._validate_config()

    @property
    @abstractmethod
    def name(self) -> str:
        """Unique connector identifier."""
        pass

    @property
    @abstractmethod
    def display_name(self) -> str:
        """Human-readable name."""
        pass

    @property
    @abstractmethod
    def capabilities(self) -> list[ConnectorCapability]:
        """What this connector can do."""
        pass

    @abstractmethod
    def _validate_config(self):
        """Validate configuration. Raise if invalid."""
        pass

    @abstractmethod
    def test_connection(self) -> tuple[bool, str]:
        """
        Test connectivity.

        Returns:
            (success, message)
        """
        pass

    def get_node_status(self, node_id: str) -> NodeStatus:
        """Get status of a specific node."""
        raise NotImplementedError(f"{self.name} does not support get_node_status")

    def get_metrics(
        self,
        node_id: str,
        metrics: list[str],
        window: str = "1h"
    ) -> MetricData:
        """Get metrics for a node."""
        raise NotImplementedError(f"{self.name} does not support get_metrics")

    def get_alerts(
        self,
        severity: str = None,
        since: str = None,
        node_id: str = None
    ) -> list[Alert]:
        """Get alerts, optionally filtered."""
        raise NotImplementedError(f"{self.name} does not support get_alerts")

    def get_inventory(self, filter: dict = None) -> list[Asset]:
        """Get asset inventory."""
        raise NotImplementedError(f"{self.name} does not support get_inventory")

    def execute_action(
        self,
        action: str,
        target: str,
        params: dict = None
    ) -> ActionResult:
        """Execute an action through this connector."""
        raise NotImplementedError(f"{self.name} does not support execute_action")
```

## Connector Registry

```python
from typing import Type, Optional

class ConnectorRegistry:
    """Manages available connectors and their instances."""

    _connector_types: dict[str, Type[Connector]] = {}
    _instances: dict[str, Connector] = {}

    @classmethod
    def register_type(cls, connector_class: Type[Connector]):
        """Register a connector type."""
        # Create temporary instance to get name
        temp = connector_class.__new__(connector_class)
        temp.config = {}
        cls._connector_types[temp.name] = connector_class
        return connector_class

    @classmethod
    def configure(cls, name: str, config: dict) -> Connector:
        """Configure and instantiate a connector."""
        if name not in cls._connector_types:
            raise ValueError(f"Unknown connector type: {name}")

        connector = cls._connector_types[name](config)
        cls._instances[name] = connector
        return connector

    @classmethod
    def get(cls, name: str) -> Optional[Connector]:
        """Get configured connector instance."""
        return cls._instances.get(name)

    @classmethod
    def list_available(cls) -> list[dict]:
        """List available connector types."""
        result = []
        for name, connector_class in cls._connector_types.items():
            temp = connector_class.__new__(connector_class)
            temp.config = {}
            result.append({
                "name": name,
                "display_name": temp.display_name,
                "capabilities": [c.value for c in temp.capabilities]
            })
        return result

    @classmethod
    def list_configured(cls) -> list[dict]:
        """List configured connector instances."""
        result = []
        for name, connector in cls._instances.items():
            success, msg = connector.test_connection()
            result.append({
                "name": name,
                "display_name": connector.display_name,
                "capabilities": [c.value for c in connector.capabilities],
                "connected": success,
                "status_message": msg
            })
        return result

    @classmethod
    def get_by_capability(cls, capability: ConnectorCapability) -> list[Connector]:
        """Get all configured connectors with a specific capability."""
        return [
            c for c in cls._instances.values()
            if capability in c.capabilities
        ]
```

## Example: Local System Connector

```python
import subprocess
import psutil
from datetime import datetime

@ConnectorRegistry.register_type
class LocalConnector(Connector):
    """Connector for local system (systemctl, journalctl, etc.)."""

    @property
    def name(self) -> str:
        return "local"

    @property
    def display_name(self) -> str:
        return "Local System"

    @property
    def capabilities(self) -> list[ConnectorCapability]:
        return [
            ConnectorCapability.METRICS,
            ConnectorCapability.LOGS,
            ConnectorCapability.INVENTORY
        ]

    def _validate_config(self):
        # Local connector doesn't need configuration
        pass

    def test_connection(self) -> tuple[bool, str]:
        try:
            result = subprocess.run(
                ["systemctl", "--version"],
                capture_output=True,
                timeout=5
            )
            return result.returncode == 0, "Local system accessible"
        except Exception as e:
            return False, str(e)

    def get_node_status(self, node_id: str = "localhost") -> NodeStatus:
        cpu = psutil.cpu_percent(interval=1)
        mem = psutil.virtual_memory()
        disk = psutil.disk_usage('/')

        return NodeStatus(
            node_id="localhost",
            name="localhost",
            status="up",
            last_seen=datetime.utcnow(),
            metrics={
                "cpu_percent": cpu,
                "memory_percent": mem.percent,
                "disk_percent": disk.percent
            }
        )

    def get_metrics(
        self,
        node_id: str,
        metrics: list[str],
        window: str = "1h"
    ) -> MetricData:
        # For local, we return current point-in-time metrics
        current = {}
        now = datetime.utcnow()

        if "cpu" in metrics:
            current["cpu"] = [(now, psutil.cpu_percent())]
        if "memory" in metrics:
            current["memory"] = [(now, psutil.virtual_memory().percent)]
        if "disk" in metrics:
            current["disk"] = [(now, psutil.disk_usage('/').percent)]

        return MetricData(
            node_id="localhost",
            metrics=current,
            window=window,
            resolution="point"
        )

    def get_inventory(self, filter: dict = None) -> list[Asset]:
        """List systemd services as inventory."""
        result = subprocess.run(
            ["systemctl", "list-units", "--type=service", "--no-pager", "--plain"],
            capture_output=True,
            text=True
        )

        assets = []
        for line in result.stdout.strip().split('\n')[1:]:  # Skip header
            parts = line.split()
            if len(parts) >= 4:
                assets.append(Asset(
                    asset_id=parts[0],
                    source="local",
                    name=parts[0],
                    asset_type="service",
                    status=parts[2],  # "running", "exited", etc.
                    metadata={"load": parts[1], "active": parts[2], "sub": parts[3]}
                ))

        return assets
```

## Example: SolarWinds Connector

```python
import requests
from datetime import datetime

@ConnectorRegistry.register_type
class SolarWindsConnector(Connector):
    """Connector for SolarWinds Orion platform."""

    @property
    def name(self) -> str:
        return "solarwinds"

    @property
    def display_name(self) -> str:
        return "SolarWinds Orion"

    @property
    def capabilities(self) -> list[ConnectorCapability]:
        return [
            ConnectorCapability.METRICS,
            ConnectorCapability.ALERTS,
            ConnectorCapability.INVENTORY,
            ConnectorCapability.TOPOLOGY
        ]

    def _validate_config(self):
        required = ["host", "username", "password"]
        for key in required:
            if key not in self.config:
                raise ValueError(f"SolarWinds connector requires '{key}' in config")

    def _api_call(self, endpoint: str, method: str = "GET", data: dict = None) -> dict:
        """Make API call to SolarWinds."""
        url = f"https://{self.config['host']}:17778/SolarWinds/InformationService/v3/Json/{endpoint}"
        auth = (self.config['username'], self.config['password'])

        response = requests.request(
            method,
            url,
            auth=auth,
            json=data,
            verify=self.config.get('verify_ssl', False),
            timeout=30
        )
        response.raise_for_status()
        return response.json()

    def test_connection(self) -> tuple[bool, str]:
        try:
            self._api_call("Query", "POST", {
                "query": "SELECT TOP 1 NodeID FROM Orion.Nodes"
            })
            return True, "Connected to SolarWinds"
        except Exception as e:
            return False, str(e)

    def get_node_status(self, node_id: str) -> NodeStatus:
        result = self._api_call("Query", "POST", {
            "query": f"""
                SELECT NodeID, Caption, Status, LastSync,
                       CPULoad, PercentMemoryUsed
                FROM Orion.Nodes
                WHERE NodeID = {node_id}
            """
        })

        if not result.get("results"):
            raise ValueError(f"Node {node_id} not found")

        node = result["results"][0]
        status_map = {1: "up", 2: "down", 3: "warning", 14: "critical"}

        return NodeStatus(
            node_id=str(node["NodeID"]),
            name=node["Caption"],
            status=status_map.get(node["Status"], "unknown"),
            last_seen=datetime.fromisoformat(node["LastSync"]),
            metrics={
                "cpu_percent": node.get("CPULoad", 0),
                "memory_percent": node.get("PercentMemoryUsed", 0)
            }
        )

    def get_alerts(
        self,
        severity: str = None,
        since: str = None,
        node_id: str = None
    ) -> list[Alert]:
        query = "SELECT AlertActiveID, AlertObjectID, Name, Severity, TriggeredDateTime FROM Orion.AlertActive"

        conditions = []
        if severity:
            severity_map = {"critical": 2, "warning": 1, "info": 0}
            conditions.append(f"Severity = {severity_map.get(severity, 0)}")
        if node_id:
            conditions.append(f"AlertObjectID = {node_id}")

        if conditions:
            query += " WHERE " + " AND ".join(conditions)

        result = self._api_call("Query", "POST", {"query": query})

        severity_reverse = {2: "critical", 1: "warning", 0: "info"}

        return [
            Alert(
                alert_id=str(a["AlertActiveID"]),
                source="solarwinds",
                severity=severity_reverse.get(a["Severity"], "info"),
                title=a["Name"],
                description=a["Name"],
                node_id=str(a["AlertObjectID"]),
                timestamp=datetime.fromisoformat(a["TriggeredDateTime"]),
                status="active"
            )
            for a in result.get("results", [])
        ]
```

## SystemConnector Agent

```python
class SystemConnectorAgent(Agent):
    """Agent that orchestrates queries across multiple connectors."""

    @property
    def name(self) -> str:
        return "system-connector"

    @property
    def description(self) -> str:
        return "Unified interface to external monitoring and management systems"

    @property
    def required_tools(self) -> list[str]:
        return []  # Uses connectors, not tools

    def run(self, context: dict) -> Evidence:
        run_id = self._generate_run_id()
        action = context.get("action")

        if action == "get_node_status":
            return self._get_node_status(run_id, context)
        elif action == "correlate_alerts":
            return self._correlate_alerts(run_id, context)
        elif action == "query":
            return self._query(run_id, context)
        else:
            raise ValueError(f"Unknown action: {action}")

    def _get_node_status(self, run_id: str, context: dict) -> Evidence:
        source = context.get("source", "auto")
        target = context["target"]

        results = {}

        if source == "auto":
            # Query all configured connectors
            for name, connector in ConnectorRegistry._instances.items():
                if ConnectorCapability.METRICS in connector.capabilities:
                    try:
                        results[name] = connector.get_node_status(target).to_dict()
                    except Exception as e:
                        results[name] = {"error": str(e)}
        else:
            connector = ConnectorRegistry.get(source)
            if not connector:
                raise ValueError(f"Connector not configured: {source}")
            results[source] = connector.get_node_status(target).to_dict()

        return Evidence(
            agent=self.name,
            run_id=run_id,
            triggered_by=TriggerType(context.get("triggered_by", "adhoc")),
            evidence={
                "action": "get_node_status",
                "target": target,
                "sources_queried": list(results.keys()),
                "results": results
            },
            conclusions=[],
            actions_taken=[],
            recommendations=[],
            next_steps=[]
        )

    def _correlate_alerts(self, run_id: str, context: dict) -> Evidence:
        sources = context.get("sources", [])
        since = context.get("since", "30m")

        all_alerts = []

        for source_name in sources:
            connector = ConnectorRegistry.get(source_name)
            if connector and ConnectorCapability.ALERTS in connector.capabilities:
                try:
                    alerts = connector.get_alerts(since=since)
                    all_alerts.extend(alerts)
                except Exception as e:
                    pass  # Log error but continue

        # Group by node
        by_node = {}
        for alert in all_alerts:
            node = alert.node_id or "unknown"
            if node not in by_node:
                by_node[node] = []
            by_node[node].append(alert)

        return Evidence(
            agent=self.name,
            run_id=run_id,
            triggered_by=TriggerType(context.get("triggered_by", "adhoc")),
            evidence={
                "action": "correlate_alerts",
                "sources_queried": sources,
                "since": since,
                "total_alerts": len(all_alerts),
                "by_node": {k: len(v) for k, v in by_node.items()},
                "alerts": [a.to_dict() for a in all_alerts]
            },
            conclusions=[
                f"Found {len(all_alerts)} alerts across {len(sources)} sources"
            ],
            actions_taken=[],
            recommendations=[],
            next_steps=[]
        )
```

## Configuration File

```yaml
# config/connectors.yaml
connectors:
  local:
    enabled: true
    # No additional config needed

  solarwinds:
    enabled: true
    host: "orion.example.com"
    username: "api-user"
    password: "${SOLARWINDS_PASSWORD}"  # Environment variable
    verify_ssl: false

  prometheus:
    enabled: false
    url: "http://prometheus:9090"

  datadog:
    enabled: false
    api_key: "${DATADOG_API_KEY}"
    app_key: "${DATADOG_APP_KEY}"
```

## Next Steps

1. Implement `connectors/base.py` with Connector interface
2. Implement `connectors/local.py` for local system
3. Implement `connectors/registry.py`
4. Build SystemConnector agent
5. Add connector configuration loading
