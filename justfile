# List recipes
list:
    @just --list

# Install skills into .claude/skills
skills:
    nix run .#skills-install-local

# List installed skills
skills-list:
    nix run .#skills-list

# Install rules into .agents/rules
rules:
    nix run .#rules-install-local

# List available rules
rules-list:
    nix run .#rules-list

# Update flake.lock, then check
update:
    nix flake update
    nix flake check

# Merge template updates from upstream
sync:
    #!/usr/bin/env bash
    set -euo pipefail
    git remote get-url upstream >/dev/null 2>&1 \
        || git remote add upstream https://github.com/Hol1kgmg/claude-temp.git
    git fetch --no-tags upstream main
    # 初回（共通祖先なし）はテンプレート生成由来の同一ファイルが全部 both added で衝突するため、
    # upstream 側を採用する。2 回目以降は独自変更を守るため通常マージ。
    # マージコミットであることが必須。squash / rebase すると共通祖先が失われ、
    # 次回以降ツリー全体が衝突する（adr/from-template/0001）
    if git merge-base HEAD upstream/main >/dev/null 2>&1; then
        git merge upstream/main --no-edit
    else
        git merge upstream/main --allow-unrelated-histories --no-edit -X theirs
    fi

# Scan working tree for secrets
scan:
    gitleaks dir --verbose

# Scan staged changes for secrets
scan-staged:
    gitleaks protect --staged --verbose

# portless が worktree のブランチ名を前置するのは run のときだけ。リポジトリ名は worktree 内でも本体の .git から取る
# PORTLESS=0 でプロキシを通さず起動したときは PORT が渡されない
# Serve markdown at http://docs.<repo>.localhost:1355
docs *ARGS:
    portless run --name docs.{{file_name(parent_directory(`git rev-parse --path-format=absolute --git-common-dir`))}} sh -c 'markserv . -p "${PORT:-8080}" -a 127.0.0.1 --browser=false "$@"' _ {{ARGS}}
