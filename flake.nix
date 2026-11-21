{
  inputs = {
    nixpkgs.url = "github:cachix/devenv-nixpkgs/rolling";
    # devenv-nixpkgs の apm-cli は websockets の版制約でビルドに失敗するため
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nur-packages.url = "github:Hol1kgmg/nur-packages";
    nix-claude-code.url = "github:ryoppippi/nix-claude-code";
    nix-claude-code.inputs.nixpkgs.follows = "nixpkgs";

    # --- project inputs: 派生先が管理。adr/from-template/0005 ---

  };

  outputs = { self, nixpkgs, nixpkgs-unstable, flake-utils, nur-packages, nix-claude-code, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        # テンプレート管理（派生先は devShells.default を編集）。adr/from-template/0005
        devShells.template = pkgs.mkShell {
          packages = [
            pkgs.just
            pkgs.jq
            pkgs.yq-go
            pkgs.gitleaks
            pkgs.lefthook
            pkgs.gh
            pkgs.git
            pkgs.dotenvx
            nur-packages.packages.${system}.markserv
            nur-packages.packages.${system}.portless
            # gh は上で別途入れているため同梱版 default ではなく minimal
            nix-claude-code.packages.${system}.claude-minimal
            pkgs.codex
            nixpkgs-unstable.legacyPackages.${system}.apm-cli
            # devenv-nixpkgs には jactionlint が無く、gh-actions-lock も古い
            nixpkgs-unstable.legacyPackages.${system}.jactionlint
            nixpkgs-unstable.legacyPackages.${system}.gh-actions-lock
            # 無いと jactionlint は run: のスクリプトを検査せずに通す
            pkgs.shellcheck
            # yomiyasu スキルのスクリプトが使う
            pkgs.python3
          ];

          shellHook = ''
            lefthook install >/dev/null
            # CI は -c で apm install --frozen を直接呼んで失敗を拾うため、ここでは二重に走らせない
            if [ -z "''${CI:-}" ] && ! out=$(apm install --frozen 2>&1); then
              printf '%s\n' "$out" >&2
              echo "apm install --frozen に失敗した。apm.yml を変えたなら just apm を実行する" >&2
            fi
          '';
        };

        # --- 派生先が管理。adr/from-template/0005 ---
        devShells.default = pkgs.mkShell {
          inputsFrom = [ self.devShells.${system}.template ];
          packages = [
          ];
        };
      });
}
