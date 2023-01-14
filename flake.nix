{
  description = "Collection of application deployment manifests for Kubernetes";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/release-22.11";
    devenv.url = "github:cachix/devenv";
  };

  outputs = { nixpkgs, devenv, ... }@inputs: {
    devShells = nixpkgs.lib.genAttrs nixpkgs.lib.platforms.unix (system:
      let pkgs = import nixpkgs { inherit system; }; in {
        default = devenv.lib.mkShell {
          inherit inputs pkgs;
          modules = [
            {
              pre-commit.hooks = {
                actionlint.enable = true;
                markdownlint.enable = true;
                shellcheck.enable = true;
                nixpkgs-fmt.enable = true;
                statix.enable = true;
                deadnix.enable = true;
              };
              packages = [
                pkgs.nixpkgs-fmt
              ];
            }
            {
              pre-commit.hooks.yamllint.enable = true;
              pre-commit.settings.yamllint.relaxed = true;
              packages = [
                pkgs.skaffold
                pkgs.kubectl
                pkgs.kustomize
                pkgs.kubernetes-helm
              ];
            }
          ];
        };
      }
    );
  };
}
