# Shared Data Files

This directory contains data files used by the DevContainer setup plugin commands and skills.

## Files

### Domain and Image Registries

- **`allowable-domains.json`** - Curated list of domains organized by category (package managers, version control, cloud platforms, etc.). Used by firewall configuration to generate domain allowlists.

- **`official-images.json`** - Registry of official Docker images with recommended tags for different languages (Python, Node, Go, Ruby, Rust, Java, etc.). Used for project type selection.

- **`sandbox-templates.json`** - Configuration templates for sandbox environments.

- **`uv-images.json`** - Python uv-specific image configurations.

### MCP Configuration

- **`mcp-servers.json`** - Model Context Protocol server configurations and metadata.

### VS Code

- **`vscode-extensions.json`** - Curated VS Code extension recommendations by category and project type.

### Environment Configuration

- **`secrets.json`** - Schema and templates for secret management (API keys, credentials, etc.).

- **`variables.json`** - Environment variable templates and build argument configurations.

## Usage

These data files are referenced by:

- `/devcontainer:setup` - Interactive setup command (reads `official-images.json`, `allowable-domains.json`)
- `/devcontainer:yolo` - Quick setup command (uses default values from these files)
- Firewall generation scripts - Read domain categories from `allowable-domains.json`

## Maintenance

When updating these files:

1. Ensure JSON schema validation passes
2. Update version numbers in file metadata
3. Test with both `/devcontainer:setup` and `/devcontainer:yolo` commands
4. Update INVENTORY.json if files are added/removed

---

**Last Updated:** 2025-12-23
**Version:** 4.3.0
