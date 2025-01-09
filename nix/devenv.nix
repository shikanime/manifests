{
  perSystem =
    { pkgs, ... }:
    {
      treefmt = {
        projectRootFile = "flake.nix";
        enableDefaultExcludes = true;
        programs = {
          actionlint.enable = true;
          deadnix.enable = true;
          nixfmt.enable = true;
          prettier.enable = true;
          shfmt.enable = true;
          statix.enable = true;
          terraform.enable = true;
        };
        settings.global.excludes = [
          "*.excalidraw"
          "*.terraform.lock.hcl"
          ".gitattributes"
          "LICENSE"
        ];
      };
      devenv.shells.default = {
        containers = pkgs.lib.mkForce { };
        languages = {
          terraform = {
            enable = true;
            package = pkgs.opentofu;
          };
          nix.enable = true;
        };
        cachix = {
          enable = true;
          push = "shikanime";
        };
        pre-commit.hooks = {
          shellcheck.enable = true;
          tflint.enable = true;
        };
        packages = [
          pkgs.gh
          pkgs.google-cloud-sdk
          pkgs.kubectl
          pkgs.kubernetes-helm
          pkgs.kustomize
          pkgs.scaleway-cli
          pkgs.skaffold
          pkgs.skopeo
          pkgs.yq-go
        ];
      };
    };
}
