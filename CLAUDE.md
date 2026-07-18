# Project Overview
{プロジェクトの概要を記述 (例: Dotfiles management project for macOS using Nix and Home-Manager)}

# Setup and Basic Usage
Setup instructions and basic usage are documented in [README.md](./README.md).

# Directory Structure
{※ディレクトリ構造のドキュメントが不要な場合はこのセクションごと削除}
See [{DIRECTORY_STRUCTURE_FILE}.md](./{DIRECTORY_STRUCTURE_FILE}.md) for details.

# Troubleshooting
{※トラブルシューティングのドキュメントが不要な場合はこのセクションごと削除}
- Setup and daily usage issues: See [{TROUBLESHOOTING_FILE}.md](./{TROUBLESHOOTING_FILE}.md)

# Work Rules
1. Propose implementation plan
2. Wait for approval
3. Start implementation

# Tool Usage Policy
**Always use dedicated tools for file operations:**
- File reading → `Read` tool
- File search → `Glob` tool
- Content search → `Grep` tool
- File editing → `Edit` tool
- File writing → `Write` tool

**Denied Bash commands:**
The following commands are blocked via Bash by `permissions.deny` in `.claude/settings.json`. Use the dedicated tools above instead.
- `ls`, `find` → `Glob` tool
- `cat`, `head`, `tail` → `Read` tool
- `grep` → `Grep` tool
- `sed`, `awk` → `Edit` tool
- `curl` → `WebFetch` tool

# Language Settings
- Responses: `.claude/settings.json` - `language`
- Thinking: English (for token reduction)
