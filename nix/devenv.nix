{
  perSystem =
    { pkgs, ... }:
    {
      treefmt = {
        projectRootFile = "flake.nix";
        enableDefaultExcludes = true;
        programs = {
          hclfmt.enable = true;
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
          nix.enable = true;
          opentofu.enable = true;
        };
        cachix = {
          enable = true;
          push = "shikanime";
        };
        git-hooks.hooks = {
          actionlint.enable = true;
          deadnix.enable = true;
          flake-checker.enable = true;
          shellcheck.enable = true;
          terraform-validate.enable = true;
          tflint.enable = true;
        };
        packages = [
          pkgs.gh
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
