{
  inputs = {
    devenv = {
      url = "github:cachix/devenv";
      inputs = {
        flake-parts.follows = "flake-parts";
        git-hooks.follows = "git-hooks";
        nixpkgs.follows = "nixpkgs";
      };
    };

    devlib = {
      url = "github:shikanime-studio/devlib";
      inputs = {
        devenv.follows = "devenv";
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
        git-hooks.follows = "git-hooks";
        treefmt-nix.follows = "treefmt-nix";
      };
    };

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };

    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
        {
          config,
          lib,
          pkgs,
          ...
        }:
        with lib;
        {
          devenv.shells.default = with config.devenv.shells.default.github.lib; {
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
            github = with config.devenv.shells.default.github.lib; {
              actions = {
                devenv-test.env.SOPS_AGE_KEY = mkWorkflowRef "secrets.SOPS_AGE_KEY";
                skaffold-run.run = "nix develop --no-pure-eval --command skaffold -- run";
              };
              workflows.release = {
                enable = true;
                settings.jobs.sync = with config.devenv.shells.default.github.actions; {
                  needs = [ "release-unstable" ];
                  runs-on = "nishir";
                  steps = [
                    create-github-app-token
                    checkout
                    setup-nix
                    skaffold-run
                  ];
                };
              };
            };
            packages = [
              pkgs.clusterctl
              pkgs.k0sctl
              pkgs.kubectl
              pkgs.kubernetes-helm
              pkgs.kustomize
              pkgs.nushell
              pkgs.skaffold
            ];
            tasks = {
              "skaffold:render:nishir-tailnet" = {
                before = [ "devenv:enterTest" ];
                exec = "${getExe pkgs.skaffold} render --profile nishir-tailnet";
              };
              "skaffold:render:telsha-tailnet" = {
                before = [ "devenv:enterTest" ];
                exec = "${getExe pkgs.skaffold} render --profile telsha-tailnet";
              };
              "sops:decrypt" = {
                before = [ "devenv:enterShell" ];
                exec = ''
                  find . -type f -name '*.enc.*' | while read -r enc; do
                    ${getExe pkgs.sops} --decrypt "$enc" > "''${enc%.enc.*}.''${enc##*.enc.}"
                  done
                '';
              };
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
            treefmt.config = {
              programs.actionlint.package =
                let
                  settingsFormat = pkgs.formats.yaml { };

                  configFile = settingsFormat.generate "actionlint.yaml" {
                    self-hosted-runner.labels = [ "nishir" ];
                  };

                  wrapped =
                    pkgs.runCommand "actionlint-wrapped"
                      {
                        buildInputs = [ pkgs.makeWrapper ];
                        meta.mainProgram = "actionlint";
                      }
                      ''
                        makeWrapper ${getExe pkgs.actionlint} $out/bin/actionlint \
                          --add-flags "-config-file ${configFile}"
                      '';
                in
                wrapped;
              settings.global.excludes = [
                "*.excalidraw"
                "*.enc.xml"
              ];
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
