# {app name}
{アプリの概要}

## 前提条件

[mise](https://mise.jdx.dev/) がインストールされ、シェルに統合されていること。

macOS (Homebrew):

```bash
brew install mise
```

シェル統合 (zsh):

```bash
echo 'eval "$(mise activate zsh)"' >> ~/.zshrc
source ~/.zshrc
```

## セットアップ

```bash
mise trust && mise run setup
```

gitleaks / lefthook のインストールと Git フックの設定が一括で行われます。

