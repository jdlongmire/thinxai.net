# Structurizr DSL - Professional C4 Diagrams

Generate enterprise-grade C4 architecture diagrams using Structurizr DSL.

## Why Structurizr?

Structurizr is the canonical way to create C4 model diagrams:
- Proper C4 model semantics (System Context → Container → Component → Code)
- Single model, multiple views
- Built-in styling and themes
- Better than Mermaid's C4 support

## C4 Model Levels

1. **System Context** - How your system fits in the world (users, external systems)
2. **Container** - High-level technology choices (web apps, APIs, databases)
3. **Component** - Inside a container (classes, modules, services)
4. **Code** - Actual code structure (UML-style)

## Instructions

When the user provides a description:

1. **Determine scope** - Which C4 levels are needed:
   - `--context` / `-1` - System context diagram
   - `--container` / `-2` - Container diagram (default)
   - `--component` / `-3` - Component diagram
   - `--all` - All three levels

2. **Create Structurizr DSL** - Generate valid DSL code

3. **Save the .dsl file** - Write to `diagrams/<name>.dsl`

4. **Render via Kroki** - Use Kroki API to render:
   ```python
   import base64
   import zlib
   import requests

   def render_structurizr(dsl_source: str, output_path: str):
       compressed = zlib.compress(dsl_source.encode('utf-8'), 9)
       encoded = base64.urlsafe_b64encode(compressed).decode('ascii')
       url = f"https://kroki.io/structurizr/png/{encoded}"
       response = requests.get(url, timeout=60)
       with open(output_path, 'wb') as f:
           f.write(response.content)
   ```

5. **Show the result** - Display generated diagram

## Structurizr DSL Reference

### Complete Example
```structurizr
workspace "ThinxAI" "AI-powered productivity system" {

    model {
        # People
        user = person "User" "Interacts with ThinxAI via chat" "User"
        admin = person "Admin" "Manages system configuration" "Admin"

        # External Systems
        openai = softwareSystem "OpenAI API" "LLM provider" "External"
        github = softwareSystem "GitHub" "Code repository" "External"

        # Main System
        thinxai = softwareSystem "ThinxAI" "AI assistant platform" {

            # Containers
            webapp = container "Web App" "Browser-based chat interface" "React/TypeScript" "Web"
            telegram = container "Telegram Bot" "Mobile chat interface" "Python" "Bot"
            api = container "API Gateway" "Routes requests to services" "FastAPI" "API"
            agent = container "Agent Service" "LLM orchestration and tool execution" "Python"
            memory = container "Memory Service" "Conversation and context management" "Python"
            db = container "PostgreSQL" "Primary data store" "PostgreSQL" "Database"
            cache = container "Redis" "Session cache and queues" "Redis" "Cache"

            # Relationships within system
            webapp -> api "HTTPS/REST"
            telegram -> api "HTTPS/REST"
            api -> agent "gRPC"
            api -> memory "gRPC"
            agent -> cache "Reads/writes"
            memory -> db "SQL"
            memory -> cache "Reads/writes"
        }

        # External relationships
        user -> webapp "Uses"
        user -> telegram "Uses"
        admin -> webapp "Configures"
        agent -> openai "API calls"
        agent -> github "API calls"
    }

    views {
        # System Context
        systemContext thinxai "SystemContext" {
            include *
            autoLayout
        }

        # Container Diagram
        container thinxai "Containers" {
            include *
            autoLayout
        }

        # Filtered views
        container thinxai "UserFlow" {
            include user webapp api agent
            autoLayout
        }

        # Styles
        styles {
            element "Person" {
                shape Person
                background #08427B
                color #ffffff
            }
            element "Software System" {
                background #1168BD
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
            element "Web" {
                shape WebBrowser
            }
            element "Database" {
                shape Cylinder
            }
            element "Cache" {
                shape Cylinder
                background #FF6B35
            }
            element "Bot" {
                shape Robot
            }
            element "API" {
                shape Hexagon
            }
        }
    }
}
```

### Key Elements

**People:**
```structurizr
user = person "Name" "Description" "Tag"
```

**Software Systems:**
```structurizr
external = softwareSystem "Name" "Description" "External"
system = softwareSystem "Name" "Description" {
    container1 = container "Name" "Description" "Technology" "Tag"
}
```

**Containers:**
```structurizr
webapp = container "Web App" "Description" "React" "Web"
api = container "API" "Description" "FastAPI" "API"
db = container "Database" "Description" "PostgreSQL" "Database"
```

**Relationships:**
```structurizr
user -> system "Uses"
container1 -> container2 "Calls" "HTTPS"
```

**Views:**
```structurizr
views {
    systemContext system "ViewName" {
        include *
        autoLayout
    }
    container system "ViewName" {
        include *
        autoLayout lr  # left-right layout
    }
}
```

### Shape Options
- `Person` - Stick figure
- `Robot` - Robot icon
- `WebBrowser` - Browser window
- `MobileDevicePortrait` - Phone
- `Cylinder` - Database
- `Folder` - File folder
- `Hexagon` - Hexagon
- `Box` - Default rectangle
- `RoundedBox` - Rounded rectangle
- `Pipe` - Queue/pipe
- `Circle` - Circle
- `Ellipse` - Ellipse

## Output Location

All diagrams are saved to: `diagrams/` in the repo root

## Example Usage

**Full C4 model for a system:**
```
/structurizr --all Create C4 diagrams for an e-commerce platform with web app, mobile app, API, and database
```

**Just container level:**
```
/structurizr --container Create a container diagram for the ThinxAI system showing webapp, API, and agents
```

**System context only:**
```
/structurizr --context Show how ThinxAI fits with users and external systems like OpenAI and GitHub
```

## Arguments

$ARGUMENTS - The system description with optional flags:
- `--context` / `-1` - System context diagram
- `--container` / `-2` - Container diagram (default)
- `--component` / `-3` - Component diagram
- `--all` - All three levels
