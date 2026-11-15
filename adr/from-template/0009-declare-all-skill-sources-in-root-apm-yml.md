---
status: 'proposed'
date: 2026-11-11
decision-makers: 'Hol1kgmg'
---

# skill / rules の取得元をすべてルートの apm.yml に直接書き、区画で分ける

## Context and Problem Statement

[ADR 0008](0008-revert-skill-sources-to-flake-inputs.md) は、Dependabot の `apm` ecosystem が取得元ごとに PR を立てないことを理由に、APM から flake input に戻した。その後の調査で、0008 の判断の根拠は次のように整理し直せた。

- 0008 の「`git:` 形式は ref を書いても対象外」に当たる取得元は、gist の 2 件と yomiyasu だった。yomiyasu は `skills:` で skill を選ぶために `git:` 形式を外せない。gist は写しで文字列形式にできるので、yomiyasu を外せばこの制約に当たる取得元はなくなる
- [ADR 0007](0007-manage-skills-and-rules-with-apm.md) の構成では、外部の取得元はすべて `packages/template/apm.yml` に書かれ、ルートの `apm.yml` はそれをローカルパスで参照するだけだった。観測した範囲では、Dependabot が更新の候補にしたのは、そのディレクトリの `apm.yml` に直接書かれ、ref の付いた依存だけだった（推移的な依存を更新しないことは、仕様として明記された記述を見つけていない）。ルートから見ると外部の取得元は推移的な依存になり、`packages/template` 側は ref がなかったため、どちらのディレクトリでもチェックの対象が 0 件になった
- 推移的な依存の commit はルートの `apm.lock.yaml` に記録されるので、版の固定はできる。できないのは、Dependabot による取得元ごとの更新である。`apm.yml` から別の `apm.yml` を呼び出すと、呼び出し先の依存はこの更新から外れる。呼び出し先がリポジトリの内か外かは関係しない
- 0008 のもう 1 つの理由である、Dependabot が使う apm の版の古さ（lock の `content_hash` が消える）は、構成を変えても残る。lock を手元で作り直せば回避できる（Decision を参照）

Dependabot で取得元ごとに更新するには、外部の取得元をすべてルートの `apm.yml` に ref 付きで直接書く必要がある。取得元にはリリースのタグがないため、ref はブランチになる。

## Decision

skill / rules の取得元と配置を APM に移す。0007 の構成のうち、宣言の置き場所を次のように変える。

- 外部の取得元は、すべてルートの `apm.yml` に `owner/repo/path#main` の形で直接書く。テンプレート管理の区画と派生先管理の区画をコメントで分け、派生先はテンプレート管理の区画を編集しない（[ADR 0005](0005-separate-template-and-project-files.md) の「別区画」）
- テンプレート独自の skill（init-from-template、template-sync-review、bot-pr-routine）は `packages/template/skills/` に置き、ルートからローカルパス `./packages/template` で参照する。ローカルなので Dependabot の対象外だが、テンプレート取り込み PR で届くので更新は要らない
- gist の skill（cognitive-rhythm-writing、japanese-tech-writing）は、Hol1kgmg/skills に定期的に写したものを参照する（Hol1kgmg/skills#1）。gist を直接書くと、名前を付けられる `git:` 形式は Dependabot の対象外で、文字列形式では配置先のディレクトリ名が gist の ID になるため
- yomiyasu はテンプレートから外す
- Dependabot の `apm` は `directory: /` だけを見る
- cooldown は守られないことを受け入れる。skill / rules の PR は自動マージせず、レビューしてから手でマージするため。apm の依存については [ADR 0003](0003-update-skill-sources-via-dependabot.md) の 2 日の cooldown をこの ADR で置き換え、`.github/dependabot.yml` の apm には効かない `cooldown` を書かない
- Dependabot が書き直した `apm.lock.yaml` で CI の `apm install --frozen` が通らない場合は、flake で固定した apm で手元から lock を作り直し、その Dependabot PR のブランチに commit して push する。人の commit が入った PR は Dependabot が自動で rebase しなくなるが、`@dependabot rebase` や `@dependabot recreate` を実行すると手で入れた commit は消える

## Consequences

- Good, because 取得元ごとに Dependabot の PR が立ち、取得元ごとに採用するか見送るかを決められる
- Good, because 取得元の追加はルートの `apm.yml` の 1 行で済む
- Bad, because テンプレートと派生先が同じ `apm.yml` と `apm.lock.yaml` を編集する。テンプレートが取得元を足したり外したりすると、`apm.yml` でも派生先の区画と隣接する行が変わり、衝突しうる。`apm.yml` の衝突は手で解消し、lock は 0007 の `scripts/resolve-locks.sh` と同じ方法で解消する
- Bad, because テンプレート管理の区画は、テンプレートと派生先の両方の Dependabot が毎週同じエントリを別の commit に進める。そのため取り込みのたびに、ほぼ毎回 lock が衝突する。[ADR 0006](0006-automate-template-sync-pr.md) の `template-dependabot-close` は nix と github-actions しか扱わないので、apm にも広げて派生先の重複 PR を閉じる
- Bad, because ブランチの ref は、取得元のリポジトリに commit があれば、その skill に関係しない変更でも PR になる
- Bad, because gist の更新は Hol1kgmg/skills の同期を経由するので、同期の間隔に Dependabot の週次の間隔を足した分だけ遅れる。同期が週次なら最大 2 週間になる
- Bad, because cooldown がかからない。公開直後の commit がそのまま PR になる
- Bad, because Dependabot の apm の版が古いままだと、lock を作り直して push する作業が、テンプレートと派生先のそれぞれで PR ごとに要る。負担になったら、この手順を workflow にする

## Implementation Plan

- **Affected paths**: `apm.yml`（新規）、`apm.lock.yaml`（新規）、`packages/template/`（新規）、`flake.nix`、`flake.lock`、`justfile`、`scripts/`、`.github/dependabot.yml`、`.github/workflows/`（`template-dependabot-close.yaml` の apm 対応を含む）、`.gitignore`、`README.md`、`docs/lockfile-automation.md`、`skills/README.md`、`rules/README.md`
- **Dependencies**: Hol1kgmg/skills#1（gist の写し）が終わっていること
- **Patterns to avoid**:
  - 外部の取得元を `packages/template/apm.yml` など、ルート以外の `apm.yml` に書くこと
  - ref のないエントリと `git:` 形式のエントリ

### Verification

- [ ] 検証ブランチで、Dependabot がルートの `apm.yml` の取得元ごとに PR を作成する
- [ ] Dependabot が使う apm の版で lock を書き直しても、手元と CI の `apm install --frozen` が通る（検証 PR #39 では apm 0.34.0 で `content_hash` が消えた）。通らない場合は、Decision の手順で作り直した lock で通ることを確かめる
- [ ] `.agents/skills` と `.claude/rules` の一覧が、0008 の構成で配置していたものから yomiyasu を除いたものと一致する

## Alternatives Considered

- **0007 の構成（テンプレートの依存を `packages/template/apm.yml` に書く）**: 外部の取得元が推移的な依存になり、Dependabot の対象から外れる
- **テンプレートの依存一覧を Hol1kgmg/skills の直下の `apm.yml` に置き、`Hol1kgmg/skills#main` を取り込む**: 同じ理由で、取得元ごとの PR が立たない。Hol1kgmg/skills の commit を進める PR が 1 本立つだけで、更新は全採用か全却下になる
- **SHA で固定する**: APM の推奨はタグか SHA だが、Dependabot と `apm update` は SHA をリリースのタグが指す commit にしか進めない。取得元にリリースのタグがないため、更新されない
- **nix の構成（0008）を続ける**: 取得元の追加が 3 か所の編集のまま残る

## More Information

- 置き換え予定: [skill / rules の取得元を flake input に戻す](0008-revert-skill-sources-to-flake-inputs.md)。この ADR を accepted にするとき、0008 を `superseded by 0009` にする
- 一部置き換え予定: [skill / rules の取得元を flake input にして Dependabot で更新する](0003-update-skill-sources-via-dependabot.md) の 2 日の cooldown（apm の依存について）。accepted にするとき、README の 0003 の status に追記する
- 前提: [skill / rules を Nix から APM に移す](0007-manage-skills-and-rules-with-apm.md)
- 調査の詳細: [apm.yml から apm.yml を呼び出すと Dependabot で更新できなくなる](research/apm-nested-dependencies.md)
- APM の依存の書き方: https://github.com/microsoft/apm/blob/main/docs/src/content/docs/consumer/manage-dependencies.md
