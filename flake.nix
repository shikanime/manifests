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
        { pkgs, ... }:
        {
          devenv.shells.default = {
            imports = [
              devlib.devenvModules.docs
              devlib.devenvModules.formats
              devlib.devenvModules.git
              devlib.devenvModules.github
              devlib.devenvModules.nix
              devlib.devenvModules.opentofu
              devlib.devenvModules.shell
              devlib.devenvModules.shikanime
            ];
            gitignore.content = [
              "app.ini"
              "config.conf"
              "config.xml"
            ];
            packages = [
              pkgs.clusterctl
              pkgs.k0sctl
              pkgs.kubectl
              pkgs.kubernetes-helm
              pkgs.kustomize
              pkgs.nushell
              pkgs.skaffold
            ];
            tasks."sops:decrypt" = {
              before = [ "devenv:enterShell" ];
              exec = ''
                find . -type f -name '*.enc.*' | while read -r enc; do
                  sops --decrypt "$enc" > "''${enc%.enc.*}.''${enc##*.enc.}"
                done
              '';
            };
            sops = {
              enable = true;
              settings = {
                creation_rules = [
                  {
                    key_groups = [
                      {
                        age = [
                          "age1045knj0kzudt68plt0snrhp7u0gffp2uh8ul4g6qy93nel5rw4wq3ag2kl" # kaltashar
                          "age1x9v4ps90txy9mk4392uya93tyzx40te4dvns4chg5s6q8mfy03ns74jpay" # nixtar
                          "age17q5ljstyzkvqtejwfnyf5jvqduars2yauw7vtgu5fcf54tm2jf0sspvt3c" # telsha
                        ];
                      }
                    ];
                  }
                ];
                stores.yaml.indent = 2;
              };
            };
            treefmt.config.settings.global.excludes = [
              "*.excalidraw"
              "*.enc.xml"
            ];
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
