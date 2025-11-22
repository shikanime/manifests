{
  inputs = {
    automata.url = "github:shikanime-studio/automata";
    devenv.url = "github:cachix/devenv";
    devlib.url = "github:shikanime-studio/devlib";
    flake-parts.url = "github:hercules-ci/flake-parts";
    git-hooks.url = "github:cachix/git-hooks.nix";
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  nixConfig = {
    extra-substituters = [
      "https://cachix.cachix.org"
      "https://devenv.cachix.org"
      "https://shikanime.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cachix.cachix.org-1:eWNHQldwUO7G2VkjpnjDbWwy4KQ/HNxht7H4SSoMckM="
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      "shikanime.cachix.org-1:OrpjVTH6RzYf2R97IqcTWdLRejF6+XbpFNNZJxKG8Ts="
    ];
  };

  outputs =
    inputs@{
      automata,
      devenv,
      devlib,
      flake-parts,
      git-hooks,
      treefmt-nix,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        devlib.flakeModule
        devenv.flakeModule
        git-hooks.flakeModule
        treefmt-nix.flakeModule
      ];
      perSystem =
        {
          self',
          pkgs,
          system,
          ...
        }:
        {
          devenv.shells.default = {
            cachix = {
              enable = true;
              push = "shikanime";
            };
            containers = pkgs.lib.mkForce { };
            gitignore = {
              enable = true;
              enableDefaultTemplates = true;
              content = [
                "config.xml"
              ];
            };
            github.enable = true;
            languages = {
              nix.enable = true;
              opentofu.enable = true;
            };
            packages = [
              automata.packages.${system}.default
              pkgs.clusterctl
              pkgs.gh
              pkgs.gnugrep
              pkgs.gnused
              pkgs.k0sctl
              pkgs.kubectl
              pkgs.kubernetes-helm
              pkgs.kustomize
              pkgs.sapling
              pkgs.skaffold
              pkgs.skopeo
              pkgs.sops
              pkgs.yq-go
            ];
            treefmt = {
              enable = true;
              config = {
                enableDefaultExcludes = true;
                programs.prettier.enable = true;
                settings.global.excludes = [
                  "*.excalidraw"
                ];
              };
            };
          };
        };
      systems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];
    };
}
