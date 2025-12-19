# Plugin Architecture

## Overview

The Claude Code Sandbox plugin uses a skills-based architecture with a data-driven template system supporting four experience modes (Basic, Intermediate, Advanced, YOLO).

## Components

### 1. Skills
- `sandbox-setup-basic` - Basic mode setup (quick automatic)
- `sandbox-setup-intermediate` - Intermediate mode setup (balanced)
- `sandbox-setup-advanced` - Advanced mode setup (secure minimal)
- `sandbox-setup-yolo` - YOLO mode setup (full control)
- `sandbox-troubleshoot` - Diagnostic assistant
- `sandbox-security` - Security auditor

### 2. Commands
- `/sandbox:basic` - Invokes Basic mode setup (quick automatic)
- `/sandbox:intermediate` - Invokes Intermediate mode setup (balanced)
- `/sandbox:advanced` - Invokes Advanced mode setup (secure minimal)
- `/sandbox:yolo` - Invokes YOLO mode setup (full control)
- `/sandbox:setup` - Interactive mode selection (or use `--basic`, `--intermediate`, etc.)
- `/sandbox:troubleshoot` - Invokes troubleshoot skill
- `/sandbox:audit` - Invokes security skill

### 3. Data Files
The plugin uses JSON data files for configuration-driven setup:

#### `/workspace/data/sandbox-templates.json`
Official Docker sandbox-templates registry with recommended images:
- Tags: `latest`, `claude-code`, `ubuntu-python`, `nightly`, `cagent`, etc.
- Metadata: OS support, architectures, image sizes, mode recommendations
- Purpose: Skills query this to present valid image options per mode

#### `/workspace/data/official-images.json`
Official Docker Hub images registry:
- Languages: Python, Node.js, Ruby, Go, Rust, PHP, Java, etc.
- Services: PostgreSQL, Redis, MySQL, MongoDB, RabbitMQ, Nginx
- Version recommendations and default tags
- Purpose: Skills use this for service selection and Dockerfile generation

#### `/workspace/data/allowable-domains.json`
Firewall domain whitelist organized by category:
- Categories: `anthropic_services`, `version_control`, `container_registries`, `package_managers`, `cloud_platforms`, etc.
- Mode defaults: Each mode has predefined domain sets
- Subcategories: Package managers organized by language
- Purpose: Skills generate firewall configs based on mode and project needs

### 4. Template System

The plugin uses a fully self-contained template organization with master source files:

#### Directory Structure
```
templates/
├── master-shared/           # Master source files (synced to skills)
│   ├── docker-compose.yml           # 2.4 KB - Source of truth
│   ├── Dockerfile.python            # 3.3 KB - Source of truth (multi-stage build)
│   ├── Dockerfile.node              # 3.0 KB - Source of truth (multi-stage build)
│   └── setup-claude-credentials.sh  # 6.2 KB - Source of truth (credential persistence)
├── master/                  # Master templates with all sections
│   ├── devcontainer.json.master
│   ├── Dockerfile.master
│   ├── docker-compose.master.yml
│   ├── init-firewall.master.sh
│   └── setup-claude-credentials.master.sh
├── compose/                 # Mode-specific compose variants
├── env/                     # Mode-specific .env templates
├── extensions/              # Mode-specific VS Code extensions
├── mcp/                     # Mode-specific MCP configs
├── variables/               # Mode-specific variable configs
└── legacy/                  # Old monolithic templates (deprecated)

skills/
├── sandbox-setup-basic/
│   └── templates/           # ALL files needed for basic mode (self-contained)
│       ├── devcontainer.json
│       ├── docker-compose.yml        # Copied from master-shared
│       ├── Dockerfile.python         # Copied from master-shared
│       ├── Dockerfile.node           # Copied from master-shared
│       ├── setup-claude-credentials.sh # Copied from master-shared
│       ├── .env.template
│       ├── extensions.json
│       ├── mcp.json
│       └── variables.json
├── sandbox-setup-intermediate/
│   └── templates/           # ALL files needed for intermediate mode
│       ├── devcontainer.json
│       ├── docker-compose.yml        # Copied from master-shared
│       ├── Dockerfile.python         # Copied from master-shared
│       ├── Dockerfile.node           # Copied from master-shared
│       ├── setup-claude-credentials.sh # Copied from master-shared
│       ├── init-firewall.sh          # 2.3 KB (permissive firewall)
│       ├── .env.template
│       ├── extensions.json
│       ├── mcp.json
│       └── variables.json
├── sandbox-setup-advanced/
│   └── templates/           # ALL files needed for advanced mode
│       ├── devcontainer.json
│       ├── docker-compose.yml        # Copied from master-shared
│       ├── Dockerfile.python         # Copied from master-shared
│       ├── Dockerfile.node           # Copied from master-shared
│       ├── setup-claude-credentials.sh # Copied from master-shared
│       ├── init-firewall.sh          # 10.8 KB (strict firewall)
│       ├── .env.template
│       ├── extensions.json
│       ├── mcp.json
│       └── variables.json
└── sandbox-setup-yolo/
    └── templates/           # ALL files needed for yolo mode
        ├── devcontainer.json
        ├── docker-compose.yml        # Copied from master-shared
        ├── Dockerfile.python         # Copied from master-shared
        ├── Dockerfile.node           # Copied from master-shared
        ├── setup-claude-credentials.sh # Copied from master-shared
        ├── init-firewall.sh          # 17.9 KB (full firewall)
        ├── .env.template
        ├── extensions.json
        ├── mcp.json
        └── variables.json
```

#### Organization Strategy

**Master Shared Files** (`templates/master-shared/`):
- Source of truth for files identical across all modes
- Updated using sync script: `./scripts/sync-templates.sh`
- Changes propagate to all skill folders
- Includes: Dockerfiles, docker-compose.yml, credentials script

**Fully Self-Contained Skills**:
- Each skill has ALL templates in its `templates/` folder
- No external directory dependencies
- Works reliably when running from any user project
- Simple skill-relative path: `$SKILL_DIR/templates`

**Sync Workflow**:
1. Edit files in `templates/master-shared/` (source of truth)
2. Run `./scripts/sync-templates.sh` to copy to all skills
3. Commit both master and synced copies

**Benefits**:
- Guaranteed template availability from skill context
- No "template not found" errors in user projects
- Simple, predictable path discovery
- Clear separation: master (edit here) vs runtime (skills)
- Minimal duplication cost (~60KB total for reliability)

#### Section Marker Format
Templates use comments to mark extractable sections:
```
// ===SECTION_START:section_name===
[content]
// ===SECTION_END:section_name===
```

Skills can:
- Extract specific sections from master templates
- Combine sections from multiple files
- Remove unused sections for cleaner output
- Customize based on mode and requirements

Example markers:
- `===SECTION_START:build===` - Build configuration
- `===SECTION_START:postgres===` - PostgreSQL service
- `===SECTION_START:firewall_basic===` - Basic firewall rules
- `===SECTION_START:extensions_advanced===` - Advanced VS Code extensions

## Four-Mode System

### Basic Mode
- **Philosophy**: Zero-configuration development
- **Target**: Beginners, rapid prototyping
- **Features**:
  - Auto-detection (2-3 questions max)
  - Sensible defaults (PostgreSQL, Redis, strict firewall)
  - Minimal VS Code extensions (5-8 essential)
  - Base image: `docker/sandbox-templates:latest` or `docker/sandbox-templates:claude-code`
  - Firewall: Essential domains only (40-50 domains)

### Intermediate Mode
- **Philosophy**: Balanced convenience and control
- **Target**: Regular developers, team projects
- **Features**:
  - Some customization (5-8 questions)
  - Build args for flexibility (Python/Node versions)
  - Curated VS Code extensions (10-15)
  - Base image: Official images (`python:3.12-slim`, `node:20-bookworm-slim`)
  - Firewall: Expanded domains including cloud platforms (100+ domains)

### Advanced Mode
- **Philosophy**: Security-first minimal surface
- **Target**: Security-conscious developers, production prep
- **Features**:
  - Detailed configuration (10-15 questions)
  - Multi-stage optimized Dockerfiles
  - Comprehensive VS Code extensions (20+)
  - Base image: Security-hardened official images
  - Firewall: Minimal whitelist, requires explicit additions (30-40 domains)

### YOLO Mode
- **Philosophy**: Maximum flexibility, user controls everything
- **Target**: Experts, custom environments, experimental setups
- **Features**:
  - Full customization (15-20+ questions)
  - Custom base images (including nightly/experimental)
  - Complete VS Code extension control
  - Base image: Any including `docker/sandbox-templates:nightly`
  - Firewall: Optional (can disable entirely) or fully custom

## Data Flow

1. User invokes mode-specific command (e.g., `/sandbox:basic`)
2. Command activates skill with mode parameter
3. Skill queries data files for mode-appropriate options:
   - `sandbox-templates.json` for base images
   - `official-images.json` for services
   - `allowable-domains.json` for firewall rules
4. Skill uses AskUserQuestion for mode-appropriate inputs
5. Skill extracts sections from master templates
6. Skill combines with mode-specific sections
7. Skill replaces placeholders with user choices
8. Skill writes output files
9. Skill provides mode-appropriate next steps

## Template Placeholder System

Templates use `{{PLACEHOLDER}}` syntax:
- `{{PROJECT_NAME}}` - Project name
- `{{NETWORK_NAME}}` - Docker network
- `{{BASE_IMAGE}}` - Docker base image from data files
- `{{FIREWALL_MODE}}` - basic/intermediate/advanced/yolo
- `{{DB_NAME}}`, `{{DB_USER}}`, `{{DB_PASSWORD}}` - Database config
- `{{REDIS_ENABLED}}` - true/false for Redis
- `{{PYTHON_VERSION}}` - Python version from official-images.json
- `{{NODE_VERSION}}` - Node.js version from official-images.json

## Skill Integration

Skills can invoke each other and share context:
- After setup → suggest security audit
- During errors → auto-invoke troubleshoot
- Before production → recommend advanced mode review

## Version 2.0 Changes

### What's New
1. **Data-driven configuration**: All options now sourced from JSON files
2. **Four-mode system**: Replaces old Basic/Advanced/YOLO with clearer modes
3. **Modular templates**: Section markers enable composable configs
4. **Enhanced firewall**: Mode-specific domain whitelists
5. **Official images**: Direct integration with Docker Hub metadata

### Migration from 1.x
- Old `templates/base/` → Now dynamically generated from `templates/master/`
- Old `templates/python/`, `templates/node/`, `templates/fullstack/` → Moved to `templates/legacy/`
- Old Basic mode → New Basic mode (similar)
- Old Advanced mode → New Intermediate mode (similar functionality)
- Old YOLO mode → New Advanced mode (security-focused) or YOLO mode (flexibility-focused)

---

**Last Updated:** 2025-12-16
**Version:** 3.0.0
