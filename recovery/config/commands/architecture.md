# Architecture Diagram Generator

Generate professional architecture diagrams from natural language descriptions.

## Available Diagram Skills

This is the main architecture skill. For specialized needs, see also:
- `/mermaid` - Quick Mermaid diagrams with new v11 types (kanban, sankey, XY charts)
- `/d2` - Modern D2 diagrams with animations and SQL tables
- `/kroki` - 20+ diagram formats via Kroki API (PlantUML, bytefield, wavedrom, etc.)
- `/structurizr` - Professional C4 architecture diagrams
- `/diagram-scan` - Auto-generate diagrams from codebase analysis

## Instructions

When the user provides a description, follow these steps:

1. **Parse arguments** - Check for flags:
   - `--light` or `-l` - Use light theme (white background)
   - `--dark` or `-d` - Use dark theme (default)
   - `--sketch` or `-s` - Hand-drawn style (Mermaid/D2)
   - `--neo` or `-n` - Modern neo theme (Mermaid only)
   - `--mermaid` or `-m` - Use Mermaid renderer
   - `--icons` or `-i` - Use Python diagrams library (AWS-style icons)
   - `--d2` - Use D2 diagram language
   - `--c4` - Use Structurizr DSL for proper C4 models

2. **Analyze the request** - Determine the best diagram type:

   **For Mermaid (`--mermaid`):**
   - `flowchart` - Process flows, decision trees, workflows
   - `sequenceDiagram` - Interactions between systems/actors over time
   - `classDiagram` - Object structures, relationships
   - `stateDiagram-v2` - State machines, lifecycle diagrams
   - `erDiagram` - Entity-relationship, data models
   - `C4Context` / `C4Container` - C4 architecture diagrams
   - `mindmap` - Hierarchical concepts
   - `kanban` - Task boards (v11)
   - `sankey-beta` - Flow diagrams (v11)
   - `xychart-beta` - Data plots (v11)
   - `block-beta` - Custom layouts (v11)

   **For D2 (`--d2`):**
   - Better auto-layout than Mermaid
   - SQL table rendering
   - Animated SVG output
   - Sequence diagrams with cleaner syntax

   **For Python diagrams (`--icons`):**
   - Infrastructure diagrams with cloud provider icons
   - System architecture with service icons
   - Best for AWS/GCP/Azure style diagrams

   **For Structurizr (`--c4`):**
   - Proper C4 model semantics
   - System Context / Container / Component views
   - Enterprise architecture

3. **Generate the diagram**

   **For Mermaid:**
   - Write to `diagrams/<name>.mmd`
   - Use theme configuration based on --light/--dark
   - Render: `mmdc -i diagrams/<name>.mmd -o diagrams/<name>.png -s 3 -b transparent`

   **For Python diagrams:**
   - Write to `diagrams/<name>.py`
   - Use appropriate theme colors
   - Run: `python3 diagrams/<name>.py`

4. **Show the result** - Display the generated PNG to the user

## Theme Configurations

### Dark Theme (default)
```python
graph_attr = {
    "bgcolor": "#1a1a1a",
    "fontcolor": "#e0e0e0",
    "fontname": "Arial",
    "fontsize": "14",
    "pad": "0.5",
    "splines": "ortho",
    "nodesep": "0.8",
    "ranksep": "1.0"
}
node_attr = {"fontcolor": "#e0e0e0", "fontname": "Arial", "fontsize": "11"}
edge_attr = {"color": "#7a7a8a", "penwidth": "2.0"}
cluster_bgcolor = "#2d2d3a"
```

### Light Theme (--light)
```python
graph_attr = {
    "bgcolor": "#ffffff",
    "fontcolor": "#333333",
    "fontname": "Arial",
    "fontsize": "14",
    "pad": "0.5",
    "splines": "ortho",
    "nodesep": "0.8",
    "ranksep": "1.0"
}
node_attr = {"fontcolor": "#333333", "fontname": "Arial", "fontsize": "11"}
edge_attr = {"color": "#666666", "penwidth": "2.0"}
# Cluster colors: light blue, light orange, light green, light purple, light pink, light cyan
```

### Mermaid Dark Theme
```
%%{init: {
  'theme': 'dark',
  'themeVariables': {
    'primaryColor': '#2d2d3a',
    'primaryTextColor': '#e0e0e0',
    'primaryBorderColor': '#5a5a6a',
    'lineColor': '#7a7a8a',
    'secondaryColor': '#1e1e2e',
    'tertiaryColor': '#252535'
  },
  'flowchart': {'curve': 'linear'}
}}%%
```

### Mermaid Light Theme
```
%%{init: {
  'theme': 'default',
  'themeVariables': {
    'primaryColor': '#e8f4fd',
    'primaryTextColor': '#333333',
    'primaryBorderColor': '#999999',
    'lineColor': '#666666'
  },
  'flowchart': {'curve': 'linear'}
}}%%
```

## Icon Library Reference (Python diagrams)

### Common Icons
| Category | Import | Icons |
|----------|--------|-------|
| Chat | `diagrams.saas.chat` | Telegram, Slack, Discord |
| VCS | `diagrams.onprem.vcs` | Github, Gitlab, Git |
| Languages | `diagrams.programming.language` | Python, Javascript, Go, Rust, Latex |
| AWS ML | `diagrams.aws.ml` | Sagemaker, Bedrock, Comprehend |
| AWS Storage | `diagrams.aws.storage` | S3, EFS, EBS |
| AWS General | `diagrams.aws.general` | Users, Client, InternetAlt1 |
| Generic | `diagrams.generic.device` | Mobile, Tablet |
| Client | `diagrams.onprem.client` | Client, User |

## Output Location

All diagrams are saved to: `diagrams/` in the repo root

## Example Usage

**AWS-style diagram with light theme:**
```
/architecture --icons --light Create a system diagram showing user authentication flow
```

**Mermaid flowchart with dark theme:**
```
/architecture --mermaid --dark Create a flowchart for the CI/CD pipeline
```

**D2 with hand-drawn style:**
```
/architecture --d2 --sketch Create a microservices architecture diagram
```

**Proper C4 model:**
```
/architecture --c4 Create a C4 container diagram for the ThinxAI platform
```

**Quick usage (defaults to icons + dark):**
```
/architecture Show the ThinxAI system architecture
```

## Renderer Comparison

| Feature | Mermaid | D2 | Python diagrams | Structurizr |
|---------|---------|-----|-----------------|-------------|
| Cloud icons | Limited | Yes | Best | Basic |
| Animations | No | Yes (SVG) | No | No |
| Auto-layout | Good | Better | Basic | Good |
| Hand-drawn | Yes | Yes | No | No |
| SQL tables | No | Yes | No | No |
| C4 model | Basic | No | No | Best |
| Data viz | Yes (v11) | No | No | No |

## Arguments

$ARGUMENTS - The diagram description and optional flags:
- `--light` / `-l` - Light theme
- `--dark` / `-d` - Dark theme (default)
- `--sketch` / `-s` - Hand-drawn style
- `--neo` / `-n` - Neo theme (Mermaid)
- `--mermaid` / `-m` - Use Mermaid
- `--icons` / `-i` - Use Python diagrams (default)
- `--d2` - Use D2
- `--c4` - Use Structurizr DSL
