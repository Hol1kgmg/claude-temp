# List available recipes for just
list:
    @just --list

# Sync agent skills into .claude/skills
skills:
    nix run .#skills-install-local

skills-list:
    nix run .#skills-list

# Update pinned skill sources (rewrites registry/sources.lock.json)
skills-update:
    nix run .#skills-sources-lock

# Scan the working tree for secrets
scan:
    gitleaks dir --verbose

# Scan staged changes for secrets
scan-staged:
    gitleaks protect --staged --verbose
