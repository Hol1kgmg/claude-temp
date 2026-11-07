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
          ];

          shellHook = ''
            lefthook install >/dev/null
            apm install --frozen >/dev/null 2>&1 || echo "apm install --frozen に失敗した。apm.yml を変えたなら just apm を実行する" >&2
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
