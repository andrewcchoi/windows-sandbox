# Repo-Keeper: Repository Organization System

**Created:** 2025-12-16
**Status:** Implemented and tested
**Purpose:** Maintain repository consistency, minimize redundancy, and ensure all components stay aligned

---

## What is Repo-Keeper?

Repo-Keeper is a comprehensive system for maintaining the sandbox-maxxing repository. It provides:

- **Organization checklist** with 18 categories covering all aspects of repository maintenance
- **Entity inventory** tracking 120+ files with rich metadata
- **Automation scripts** for version sync, link checking, and inventory validation
- **GitHub workflows** for CI/CD integration
- **Issue/PR templates** for standardized contributions

---

## What Was Created

### ✅ Phase 1: Core Structure

| File | Purpose | Lines |
|------|---------|-------|
| `ORGANIZATION_CHECKLIST.md` | 18-category maintenance checklist with implementation guides | 1000+ |
| `INVENTORY.json` | Rich metadata inventory of all repo entities (skills, commands, templates, examples, etc.) | 600+ |

### ✅ Phase 2: Automation Scripts

| File | Purpose | Platform |
|------|---------|----------|
| `scripts/check-version-sync.ps1` | Validates version consistency across 50+ files | PowerShell (Windows) |
| `scripts/check-version-sync.sh` | Bash version of version checker | Bash (Linux/macOS) |
| `scripts/check-links.ps1` | Scans markdown files for broken internal links | PowerShell |
| `scripts/validate-inventory.ps1` | Verifies inventory matches filesystem | PowerShell |

### ✅ Phase 3: GitHub Integration

| File | Purpose |
|------|---------|
| `workflows/validate-versions.yml` | GitHub Action for automated version checking on PRs |
| `workflows/validate-links.yml` | Weekly link validation with PR comments |
| `templates/ISSUE_TEMPLATE/bug_report.md` | Mode-specific bug report template |
| `templates/ISSUE_TEMPLATE/feature_request.md` | Structured feature proposal template |
| `templates/ISSUE_TEMPLATE/config.yml` | Issue template configuration |
| `templates/PULL_REQUEST_TEMPLATE.md` | Comprehensive PR checklist |

### ✅ Phase 4: Documentation Updates

- **README.md** - Added "Repository Maintenance" section linking to repo-keeper
- **CONTRIBUTING.md** - Added "Repository Organization" section with validation guidelines

---

## Directory Structure

```
docs/repo-keeper/
├── README.md                          # This file
├── ORGANIZATION_CHECKLIST.md          # 18-category checklist
├── INVENTORY.json                     # Entity inventory
├── scripts/
│   ├── check-version-sync.ps1         # Version validation (PowerShell)
│   ├── check-version-sync.sh          # Version validation (Bash)
│   ├── check-links.ps1                # Link checker
│   └── validate-inventory.ps1         # Inventory validator
├── workflows/
│   ├── validate-versions.yml          # GitHub Action for versions
│   └── validate-links.yml             # GitHub Action for links
└── templates/
    ├── ISSUE_TEMPLATE/
    │   ├── bug_report.md
    │   ├── feature_request.md
    │   └── config.yml
    └── PULL_REQUEST_TEMPLATE.md
```

---

## Test Results (2025-12-16)

### Version Sync Check

```
✅ INVENTORY.json: 2.2.1 (correct)
❌ data/secrets.json: 2.1.0 (needs update to 2.2.1)
❌ data/variables.json: 2.1.0 (needs update to 2.2.1)
✅ 51 files with matching version footers
⚠️  11 files missing footers
```

**Status:** Script working correctly, identified 3 issues to fix

### Known Issues Found

1. **Version mismatches (3 files):**
   - `data/secrets.json` - shows 2.1.0, should be 2.2.1
   - `data/variables.json` - shows 2.1.0, should be 2.2.1
   - `.claude-plugin/marketplace.json` - version field parsing issue

2. **Missing version footers (11 files):**
   - Various documentation files need footers added

3. **Broken links (10 known):**
   - From previous audit in `docs/CONSISTENCY_AUDIT_2025-12-16.md`
   - `docs/CONSOLIDATION_RECOMMENDATIONS.md` (3 links)
   - `skills/sandbox-setup-advanced/references/` (2 links)
   - `templates/legacy/README.md` (3 links)
   - Archive files (2 links)

---

## Quick Start Guide

### 1. Run Local Validation

Before committing changes, run these scripts:

```powershell
# PowerShell (Windows)
cd D:\!wip\sandbox-maxxing

# Check version consistency
.\docs\repo-keeper\scripts\check-version-sync.ps1

# Check for broken links
.\docs\repo-keeper\scripts\check-links.ps1

# Validate inventory against filesystem
.\docs\repo-keeper\scripts\validate-inventory.ps1

# Find orphaned files not in inventory
.\docs\repo-keeper\scripts\validate-inventory.ps1 -FindOrphans

# Verbose output
.\docs\repo-keeper\scripts\check-version-sync.ps1 -Verbose
```

```bash
# Bash (Linux/macOS/WSL)
cd /workspace  # or your repo location

# Check version consistency
./docs/repo-keeper/scripts/check-version-sync.sh

# With verbose output
./docs/repo-keeper/scripts/check-version-sync.sh --verbose
```

### 2. Activate GitHub Workflows (Optional)

Copy workflows to activate automated checks:

```powershell
# Create .github directory if it doesn't exist
New-Item -ItemType Directory -Path ".github\workflows" -Force

# Copy workflows
Copy-Item -Path "docs\repo-keeper\workflows\*" -Destination ".github\workflows\" -Force

# Copy issue/PR templates
Copy-Item -Path "docs\repo-keeper\templates\ISSUE_TEMPLATE" -Destination ".github\" -Recurse -Force
Copy-Item -Path "docs\repo-keeper\templates\PULL_REQUEST_TEMPLATE.md" -Destination ".github\" -Force
```

### 3. Fix Known Issues

**High Priority:**

1. Update data file versions:
   ```powershell
   # Edit data/secrets.json
   # Change "version": "2.1.0" to "version": "2.2.1"

   # Edit data/variables.json
   # Change "version": "2.1.0" to "version": "2.2.1"
   ```

2. Add version footers to 11 files (see checklist)

3. Fix 10 broken links (see checklist)

**Medium Priority:**

- Document or remove `data/mcp-servers.json`
- Fix plugin naming in `data/README.md`

---

## How to Use the Checklist

The [`ORGANIZATION_CHECKLIST.md`](./ORGANIZATION_CHECKLIST.md) contains 18 categories:

1. **Changelog Management** - CHANGELOG.md format and version sync
2. **Version Footer Consistency** - 47 files with version footers
3. **Skills, Templates, Examples Alignment** - Mode coverage matrix
4. **Redundancy Minimization Rules** - When to duplicate vs consolidate
5. **Discrepancy Prevention** - Version numbers, naming, descriptions
6. **Cross-Reference Integrity** - No broken links
7. **Data Files Consistency** - JSON files in `data/`
8. **Consolidation Rules** - Documentation hierarchy
9. **Naming Conventions** - Commands, skills, templates, examples
10. **CI/CD Automation** - GitHub Actions implementation
11. **Dependency Version Sync** - requirements.txt, package.json
12. **DevContainer Config Sync** - 6 devcontainer locations
13. **Template Hierarchy Sync** - Master → mode → examples
14. **Firewall Script Sync** - 8 firewall script files
15. **Dockerfile Sync** - 21 Dockerfile locations
16. **Test File Consistency** - Jest + Pytest configs
17. **EditorConfig Standardization** - Decision needed
18. **Inventory Maintenance** - Keep INVENTORY.json current

**Usage:**
- Review checklist before releases
- Reference when adding new files
- Use as PR review guide

---

## How to Use the Inventory

The [`INVENTORY.json`](./INVENTORY.json) tracks:

- **6 skills** with relationships to commands, examples, templates
- **7 commands** with skill invocations
- **48 templates** categorized by type and mode
- **7 examples** with test info and devcontainer paths
- **7 data files** with version and update frequency
- **50+ documentation files** with footer status
- **6 devcontainers** with mode and paths
- **14 dependency files** (Python + Node.js)
- **Test files** (manual, jest, pytest)

**Usage:**
- Validate with `validate-inventory.ps1`
- Update when adding/removing files
- Reference for understanding relationships
- Use for auditing and reporting

---

## Maintenance Schedule

### On Every Commit
- Run link checker (if CI/CD active)
- Verify no broken references

### On Every Version Bump
1. Update `CHANGELOG.md` with new version header
2. Update all version footers in documentation
3. Update `plugin.json` and `marketplace.json`
4. Update `INVENTORY.json` version
5. Update `data/secrets.json` and `variables.json` versions
6. Run `scripts/check-version-sync.ps1` to verify

### Monthly
- Review and update `data/official-images.json` tags
- Check for security updates in dependencies
- Scan for broken external links

### Quarterly
- Run full consistency audit
- Review consolidation opportunities
- Check for new redundancy
- Update domain allowlists

### Before Each Release
- Review ORGANIZATION_CHECKLIST.md
- Review `docs/RELEASE_CHECKLIST.md`
- Run all validation scripts
- Test manual procedures

---

## Next Steps (Picking Up Where We Left Off)

### Immediate Actions

1. **Fix version mismatches:**
   - [ ] Update `data/secrets.json` to 2.2.1
   - [ ] Update `data/variables.json` to 2.2.1
   - [ ] Fix `marketplace.json` version field parsing

2. **Add missing footers (11 files):**
   - [ ] Run version sync with `-Verbose` to see which files
   - [ ] Add standard footer to each:
     ```markdown
     ---

     **Last Updated:** 2025-12-16
     **Version:** 2.2.1
     ```

3. **Fix broken links (10 known):**
   - [ ] Run link checker to identify
   - [ ] Update relative paths
   - [ ] Test links work

### Optional Enhancements

4. **Activate CI/CD:**
   - [ ] Copy workflows to `.github/workflows/`
   - [ ] Test workflows on a feature branch
   - [ ] Adjust paths if needed (D:\!wip\sandbox-maxxing vs /workspace)

5. **Add Issue/PR Templates:**
   - [ ] Copy templates to `.github/`
   - [ ] Test issue creation
   - [ ] Test PR creation

6. **Create bash version of link checker:**
   - [ ] Port `check-links.ps1` to bash
   - [ ] Save as `scripts/check-links.sh`
   - [ ] Test on Linux/macOS

### Long-term Improvements

7. **Automate inventory updates:**
   - Create script to regenerate INVENTORY.json from filesystem
   - Add to pre-commit hook

8. **Add JSON schemas:**
   - Create `inventory.schema.json` for validation
   - Create schemas for data files

9. **EditorConfig standardization:**
   - Decide: Add to all examples or remove from YOLO
   - Implement chosen approach

---

## Troubleshooting

### Script Won't Run

**PowerShell Execution Policy:**
```powershell
# Check current policy
Get-ExecutionPolicy

# Allow scripts (run as Administrator)
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Path Issues:**
- Scripts use `D:\!wip\sandbox-maxxing` as repo root
- Update `$repoRoot` variable in scripts if your path differs
- Bash scripts use `/workspace` (for devcontainer)

### False Positives

**Version sync script:**
- CHANGELOG.md is excluded (doesn't need footer)
- Archive files in `docs/archive/` don't need footers

**Link checker:**
- External links are skipped by default
- Anchors (#links) are skipped
- Fragment identifiers (#section) are removed before validation

### Performance

**Large repository:**
- Use `-Verbose` only when debugging
- Link checker can be slow on 50+ markdown files
- Inventory validation is fast (<1 second)

---

## Reference Links

### Project Documentation
- [Main README](../../README.md)
- [CONTRIBUTING](../../CONTRIBUTING.md)
- [DEVELOPMENT](../../DEVELOPMENT.md)
- [CHANGELOG](../../CHANGELOG.md)

### Existing Audits
- [Consistency Audit](../CONSISTENCY_AUDIT_2025-12-16.md)
- [Consolidation Recommendations](../CONSOLIDATION_RECOMMENDATIONS.md)
- [Release Checklist](../RELEASE_CHECKLIST.md)

### Related Docs
- [MODES.md](../MODES.md) - Mode comparison guide
- [TROUBLESHOOTING.md](../TROUBLESHOOTING.md) - Issue resolution
- [ARCHITECTURE.md](../ARCHITECTURE.md) - System design

---

## Contact & Support

For questions about repo-keeper:
1. Check the [ORGANIZATION_CHECKLIST.md](./ORGANIZATION_CHECKLIST.md)
2. Review this README
3. Open an issue on GitHub

For general plugin support:
- **Issues**: https://github.com/andrewcchoi/sandbox-maxxing/issues
- **Documentation**: See `skills/*/references/` directories

---

**Version:** 2.2.1
**Last Updated:** 2025-12-16
**Status:** ✅ Implemented and tested
