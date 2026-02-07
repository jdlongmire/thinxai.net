# RAG Architecture for ThinxAI-Maestro

## Overview

ThinxAI-Maestro uses a **tiered knowledge architecture** with unified query interface. Agents query knowledge through a single API; the RAG engine routes queries across internal stores, external knowledge bases, and internet sources based on context and confidence requirements.

## Tiered Knowledge Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          Agent Query                                     │
│  "Why is web-server-01 slow? Check similar issues and vendor docs."     │
└────────────────────────────────┬────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                       RAG Orchestrator                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                   │
│  │Query Router  │──│Confidence    │──│Result Merger │                   │
│  │              │  │Scorer        │  │              │                   │
│  └──────────────┘  └──────────────┘  └──────────────┘                   │
└────────────────────────────────┬────────────────────────────────────────┘
                                 │
         ┌───────────────────────┼───────────────────────┐
         ▼                       ▼                       ▼
┌─────────────────┐   ┌─────────────────┐   ┌─────────────────┐
│   Tier 1        │   │   Tier 2        │   │   Tier 3        │
│   INTERNAL      │   │   SPECIALIZED   │   │   INTERNET      │
│   (Highest      │   │   (Curated      │   │   (Supplemental │
│   trust)        │   │   external)     │   │   context)      │
└────────┬────────┘   └────────┬────────┘   └────────┬────────┘
         │                     │                     │
         ▼                     ▼                     ▼
  ┌────────────┐        ┌────────────┐        ┌────────────┐
  │Operations  │        │Vendor KBs  │        │Web Search  │
  │History     │        │CVE/NVD     │        │LLM Context │
  │Runbooks    │        │RFC/Specs   │        │Forums      │
  │Baselines   │        │Cloud Docs  │        │Blogs       │
  └────────────┘        └────────────┘        └────────────┘
```

## Knowledge Tiers

### Tier 1: Internal Knowledge (Highest Trust)

Organizational data with full provenance. **Always queried first.**

| Category | Contents | Updated | Trust |
|----------|----------|---------|-------|
| **operations/incidents** | Past incidents, root causes, resolutions | After each incident | 100% |
| **operations/baselines** | Normal ranges per node/service/time | Daily rollup | 100% |
| **operations/changes** | Deployments, config changes | Real-time | 100% |
| **operations/alerts** | Alert patterns, false positive markers | After analysis | 100% |
| **runbooks/procedures** | SOPs, troubleshooting, escalation | Manual | 100% |
| **runbooks/architecture** | Topology, dependencies, ownership | Periodic | 100% |
| **evidence/agent-runs** | Prior agent outputs, analysis history | After each run | 100% |
| **evidence/remediation** | What worked, what didn't | After resolution | 100% |

### Tier 2: Specialized External Knowledge Bases (High Trust)

Curated, authoritative external sources. **Queried for technical depth.**

| Category | Source | Updated | Trust | Use Case |
|----------|--------|---------|-------|----------|
| **security/cve** | NVD, CVE databases | Daily sync | 95% | Vulnerability context |
| **security/mitre** | MITRE ATT&CK | Weekly sync | 95% | Threat patterns |
| **vendor/microsoft** | MS Learn, TechNet | Weekly | 90% | Windows/Azure issues |
| **vendor/linux** | Kernel docs, distro KBs | Weekly | 90% | Linux troubleshooting |
| **vendor/cloud** | AWS/GCP/Azure docs | Weekly | 90% | Cloud platform issues |
| **standards/rfc** | IETF RFCs | Monthly | 95% | Protocol specifications |
| **standards/owasp** | OWASP resources | Monthly | 95% | Security best practices |

### Tier 3: Internet Sources (Supplemental)

Live web search for current context. **Queried for edge cases.**

| Source | Method | Trust | Use Case |
|--------|--------|-------|----------|
| **Web Search** | Search API (Brave/Google) | 60-80% | Current issues, patches |
| **Stack Overflow** | API or search | 70% | Developer solutions |
| **GitHub Issues** | GitHub API | 75% | OSS bug context |
| **Vendor Forums** | Scraping/API | 65% | Community fixes |
| **Tech Blogs** | Search | 50% | Alternative approaches |

---

## Ingestion Interface

### Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Ingestion Manager                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                   │
│  │Queue Manager │──│Processor    │──│Store Writer  │                   │
│  │              │  │Pipeline     │  │              │                   │
│  └──────────────┘  └──────────────┘  └──────────────┘                   │
└────────────────────────────────┬────────────────────────────────────────┘
                                 │
    ┌────────────┬───────────────┼───────────────┬────────────┐
    ▼            ▼               ▼               ▼            ▼
┌────────┐  ┌────────┐     ┌────────┐     ┌────────┐    ┌────────┐
│Push API│  │File    │     │Webhook │     │Scheduled│   │Stream  │
│        │  │Watch   │     │Handler │     │Pull     │   │Consumer│
└────────┘  └────────┘     └────────┘     └────────┘   └────────┘
```

### Ingestion Methods

```python
class IngestionManager:
    """
    Unified ingestion interface for all knowledge sources.
    """

    # === PUSH METHODS (Real-time) ===

    def ingest_document(self,
                        tier: str,
                        category: str,
                        document: Document,
                        metadata: dict = None) -> str:
        """
        Direct document ingestion.

        Args:
            tier: "internal", "specialized", "internet"
            category: Category path (e.g., "operations/incidents")
            document: Document to ingest
            metadata: Additional metadata

        Returns:
            Document ID
        """
        pass

    def ingest_batch(self,
                     tier: str,
                     category: str,
                     documents: list[Document],
                     dedupe: bool = True) -> IngestionResult:
        """
        Batch ingestion with optional deduplication.
        """
        pass

    def ingest_from_evidence(self, evidence: Evidence) -> str:
        """
        Ingest agent evidence into internal knowledge.
        Auto-categorizes based on agent type and outcome.
        """
        pass

    # === PULL METHODS (Scheduled) ===

    def register_source(self,
                        source: KnowledgeSource,
                        schedule: str,
                        tier: str,
                        category: str) -> str:
        """
        Register an external source for scheduled pulls.

        Args:
            source: Source connector (e.g., NVDSource, MSDocsSource)
            schedule: Cron expression (e.g., "0 2 * * *" for daily 2AM)
            tier: Target tier
            category: Target category

        Returns:
            Source registration ID
        """
        pass

    def pull_now(self, source_id: str) -> IngestionResult:
        """Force immediate pull from a registered source."""
        pass

    # === FILE WATCH ===

    def watch_directory(self,
                        path: str,
                        tier: str,
                        category: str,
                        pattern: str = "*.md") -> str:
        """
        Watch directory for new/modified files.
        """
        pass

    # === WEBHOOKS ===

    def get_webhook_endpoint(self, tier: str, category: str) -> str:
        """
        Get webhook URL for external systems to push data.
        Returns: https://maestro.local/ingest/{tier}/{category}
        """
        pass

    # === STREAMING ===

    def subscribe_stream(self,
                         stream: str,
                         tier: str,
                         category: str,
                         filter: dict = None) -> str:
        """
        Subscribe to event stream (Kafka, Redis Streams, etc.)
        """
        pass
```

### Source Connectors

```python
class KnowledgeSource(ABC):
    """Base class for external knowledge sources."""

    @property
    @abstractmethod
    def name(self) -> str:
        """Unique source name."""
        pass

    @property
    @abstractmethod
    def tier(self) -> str:
        """Default tier: 'specialized' or 'internet'"""
        pass

    @abstractmethod
    def fetch(self, since: datetime = None) -> list[Document]:
        """Fetch documents from source."""
        pass

    @abstractmethod
    def health_check(self) -> bool:
        """Verify source is accessible."""
        pass


class NVDSource(KnowledgeSource):
    """NIST National Vulnerability Database."""
    name = "nvd"
    tier = "specialized"

    def fetch(self, since: datetime = None) -> list[Document]:
        # Query NVD API for CVEs
        # Transform to Documents with metadata
        pass


class MSDocsSource(KnowledgeSource):
    """Microsoft documentation (Learn, TechNet)."""
    name = "microsoft-docs"
    tier = "specialized"

    def fetch(self, since: datetime = None) -> list[Document]:
        # Crawl/API MS Learn
        # Focus on KB articles, troubleshooting
        pass


class WebSearchSource(KnowledgeSource):
    """Live web search for Tier 3."""
    name = "web-search"
    tier = "internet"

    def fetch(self, query: str, max_results: int = 10) -> list[Document]:
        # Use search API (Brave, Google, etc.)
        # Return with source URLs and trust scores
        pass
```

---

## Unified Query Interface

```python
@dataclass
class QueryConfig:
    """Configuration for knowledge query."""
    tiers: list[str] = field(default_factory=lambda: ["internal", "specialized"])
    categories: list[str] = None  # None = all in tier
    min_confidence: float = 0.7
    max_results: int = 10
    include_internet: bool = False  # Explicit opt-in for Tier 3
    require_provenance: bool = True

@dataclass
class RetrievalResult:
    """Single retrieval result with full provenance."""
    content: str
    score: float
    tier: str
    category: str
    source: str
    timestamp: datetime
    trust_score: float
    metadata: dict

class KnowledgeQuery:
    """
    Unified query interface across all tiers.
    """

    def query(self,
              query: str,
              config: QueryConfig = None) -> list[RetrievalResult]:
        """
        Query knowledge across tiers.

        Routing:
        1. Always query Tier 1 (internal)
        2. Query Tier 2 if categories specified or internal lacks coverage
        3. Query Tier 3 only if explicitly enabled

        Returns:
            Results merged and ranked by relevance * trust
        """
        pass

    def query_with_context(self,
                           query: str,
                           context: dict,
                           config: QueryConfig = None) -> RetrievalResult:
        """
        Query with operational context for better routing.

        Context example:
        {
            "node": "web-server-01",
            "symptom": "high CPU",
            "timeframe": "last 2 hours",
            "already_tried": ["restart", "clear cache"]
        }
        """
        pass

    def get_baseline(self,
                     node: str,
                     metric: str,
                     time_window: str = "7d") -> BaselineStats:
        """Get statistical baseline from internal operations data."""
        pass

    def search_internet(self,
                        query: str,
                        max_results: int = 5) -> list[RetrievalResult]:
        """
        Explicit Tier 3 search.
        Results marked with trust scores and source URLs.
        """
        pass
```

---

## Category-Based Collections

### Internal (Tier 1)

```yaml
internal:
  operations:
    incidents:
      description: Past incidents with root cause analysis
      schema: incident
      retention: 2y
      embeddings: content + metadata

    baselines:
      description: Statistical baselines per node/metric
      schema: baseline
      retention: 90d rolling
      embeddings: none (structured query)

    changes:
      description: Configuration and deployment changes
      schema: change
      retention: 1y
      embeddings: description + affected_systems

    alerts:
      description: Alert history and patterns
      schema: alert
      retention: 6m
      embeddings: message + metadata

  runbooks:
    procedures:
      description: Standard operating procedures
      schema: runbook
      retention: permanent
      embeddings: content + steps

    architecture:
      description: System topology and ownership
      schema: architecture
      retention: permanent
      embeddings: description + dependencies

  evidence:
    agent_runs:
      description: Prior agent investigation outputs
      schema: evidence
      retention: 1y
      embeddings: conclusions + observations

    remediation:
      description: Resolution history
      schema: remediation
      retention: 2y
      embeddings: problem + solution
```

### Specialized (Tier 2)

```yaml
specialized:
  security:
    cve:
      source: NVD API
      schedule: "0 4 * * *"  # Daily 4 AM
      embeddings: description + affected_products

    mitre:
      source: MITRE ATT&CK
      schedule: "0 5 * * 0"  # Weekly Sunday
      embeddings: technique_description

  vendor:
    microsoft:
      source: MS Learn scraper
      schedule: "0 3 * * *"
      embeddings: content + symptoms

    linux:
      source: Kernel docs, distro KBs
      schedule: "0 3 * * 0"
      embeddings: content

    cloud:
      source: AWS/GCP/Azure docs
      schedule: "0 3 * * *"
      embeddings: content + services

  standards:
    rfc:
      source: IETF datatracker
      schedule: "0 6 1 * *"  # Monthly
      embeddings: abstract + content

    owasp:
      source: OWASP site
      schedule: "0 6 1 * *"
      embeddings: content
```

---

## Agent Integration Example

```python
class IncidentInvestigator(Agent):
    """Agent that investigates incidents using tiered knowledge."""

    def __init__(self, system_connector, knowledge: KnowledgeQuery, ingestion: IngestionManager):
        self.system_connector = system_connector
        self.knowledge = knowledge
        self.ingestion = ingestion

    def run(self, context: dict) -> Evidence:
        symptom = context["symptom"]
        node = context["node"]

        # 1. Get current state from monitoring systems
        current = self.system_connector.get_node_status(node)

        # 2. RAG Tier 1: Internal history
        internal_results = self.knowledge.query(
            query=f"{symptom} on {node}",
            config=QueryConfig(
                tiers=["internal"],
                categories=["operations/incidents", "evidence/agent_runs"],
                max_results=5
            )
        )

        # 3. RAG Tier 1: What changed recently?
        changes = self.knowledge.query(
            query=f"changes affecting {node}",
            config=QueryConfig(
                tiers=["internal"],
                categories=["operations/changes"],
                max_results=5
            )
        )

        # 4. RAG Tier 1: Is this anomalous?
        baseline = self.knowledge.get_baseline(
            node=node,
            metric="cpu",
            time_window="7d"
        )

        # 5. RAG Tier 2: Vendor knowledge (if symptom suggests)
        vendor_docs = None
        if self._might_need_vendor_docs(symptom, current):
            vendor_docs = self.knowledge.query(
                query=f"troubleshoot {symptom}",
                config=QueryConfig(
                    tiers=["specialized"],
                    categories=["vendor/microsoft", "vendor/linux"],
                    max_results=3
                )
            )

        # 6. RAG Tier 3: Internet (only if no internal/specialized hits)
        internet_results = None
        if not internal_results and not vendor_docs:
            internet_results = self.knowledge.search_internet(
                query=f"{symptom} {current.os} troubleshoot",
                max_results=3
            )

        # 7. Get runbooks
        runbooks = self.knowledge.query(
            query=f"troubleshoot {symptom}",
            config=QueryConfig(
                tiers=["internal"],
                categories=["runbooks/procedures"],
                max_results=2
            )
        )

        # 8. Synthesize and return evidence
        evidence = self.analyze(
            current, internal_results, changes, baseline,
            vendor_docs, internet_results, runbooks
        )

        # 9. Ingest this run for future reference
        self.ingestion.ingest_from_evidence(evidence)

        return evidence
```

---

## Storage Architecture

```
thinxai-maestro/
├── knowledge/
│   ├── __init__.py
│   ├── orchestrator.py          # RAG Orchestrator (routes across tiers)
│   ├── query.py                 # KnowledgeQuery interface
│   │
│   ├── tiers/
│   │   ├── __init__.py
│   │   ├── base.py              # TierStore abstract class
│   │   ├── internal.py          # Tier 1: ChromaDB/Qdrant
│   │   ├── specialized.py       # Tier 2: Separate collections
│   │   └── internet.py          # Tier 3: Search API wrapper
│   │
│   ├── ingestion/
│   │   ├── __init__.py
│   │   ├── manager.py           # IngestionManager
│   │   ├── queue.py             # Ingestion queue
│   │   ├── processors/
│   │   │   ├── markdown.py      # Parse .md files
│   │   │   ├── json.py          # Parse structured data
│   │   │   └── html.py          # Parse web content
│   │   └── sources/
│   │       ├── base.py          # KnowledgeSource ABC
│   │       ├── nvd.py           # NVD/CVE source
│   │       ├── msdocs.py        # Microsoft docs
│   │       ├── github.py        # GitHub issues
│   │       └── web_search.py    # Search API
│   │
│   ├── embeddings/
│   │   ├── __init__.py
│   │   ├── local.py             # sentence-transformers
│   │   └── cache.py             # Embedding cache
│   │
│   └── collections/
│       ├── __init__.py
│       ├── incidents.py
│       ├── baselines.py
│       ├── runbooks.py
│       ├── changes.py
│       └── evidence.py
│
├── data/
│   ├── vectordb/
│   │   ├── internal/            # Tier 1 ChromaDB
│   │   └── specialized/         # Tier 2 ChromaDB
│   └── ingestion/
│       ├── queue/               # Pending ingestion
│       └── failed/              # Failed items for retry
│
└── config/
    ├── knowledge.yaml           # Categories, retention, schedules
    └── sources.yaml             # External source configs
```

---

## Configuration

```yaml
# config/knowledge.yaml

tiers:
  internal:
    store: chromadb
    path: data/vectordb/internal
    embedding_model: all-MiniLM-L6-v2
    default_trust: 1.0

  specialized:
    store: chromadb
    path: data/vectordb/specialized
    embedding_model: all-mpnet-base-v2
    default_trust: 0.9

  internet:
    search_provider: brave  # or: google, bing
    api_key_env: SEARCH_API_KEY
    default_trust: 0.6
    cache_ttl: 3600  # 1 hour

ingestion:
  queue_path: data/ingestion/queue
  failed_path: data/ingestion/failed
  max_retries: 3
  batch_size: 100

  sources:
    nvd:
      enabled: true
      schedule: "0 4 * * *"
      tier: specialized
      category: security/cve

    msdocs:
      enabled: true
      schedule: "0 3 * * *"
      tier: specialized
      category: vendor/microsoft
      topics:
        - windows-server/troubleshoot
        - azure/monitoring
```

---

## Dependencies

```toml
# pyproject.toml additions
[project.dependencies]
chromadb = ">=0.4.0"
sentence-transformers = ">=2.2.0"
httpx = ">=0.24.0"           # Async HTTP for sources
beautifulsoup4 = ">=4.12.0"  # HTML parsing
pyyaml = ">=6.0"             # Config
schedule = ">=1.2.0"         # Cron scheduling
# Future:
# qdrant-client = ">=1.6.0"

[project.optional-dependencies]
search = [
    "brave-search = ">=0.1.0"  # Brave Search API
]
```

---

## Traceability

| Decision | Rationale | Date |
|----------|-----------|------|
| Three-tier architecture | Separate trust levels, different update patterns | 2026-02-07 |
| Internal first, always | Organizational knowledge is highest trust | 2026-02-07 |
| Opt-in internet search | Prevent noise; explicit when needed | 2026-02-07 |
| Category-based organization | Different retention, embedding, query patterns per type | 2026-02-07 |
| Unified IngestionManager | Single API for all ingestion patterns | 2026-02-07 |
| Source connectors pattern | Pluggable external sources | 2026-02-07 |
| Trust scores on results | Agents can weight by source reliability | 2026-02-07 |

---

*Related: [agent-architecture.md](agent-architecture.md), [connector-interface.md](connector-interface.md)*
