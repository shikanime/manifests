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
      inputs.nixpkgs.follows = "nixpkgs";
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
          devenv = {
            modules = [
              {
                sops = {
                  enable = true;
                  settings.creation_rules = [
                    {
                      key_groups = [
                        {
                          age = [
                            "age1045knj0kzudt68plt0snrhp7u0gffp2uh8ul4g6qy93nel5rw4wq3ag2kl" # kaltashar
                            "age17q5ljstyzkvqtejwfnyf5jvqduars2yauw7vtgu5fcf54tm2jf0sspvt3c" # telsha
                            "age1dnxv9pweev9aqm5d6a8ylnw2z3tjds2hed5j73awtqmyr0cy354q068md4" # github
                            "age1x9v4ps90txy9mk4392uya93tyzx40te4dvns4chg5s6q8mfy03ns74jpay" # nixtar
                          ];
                        }
                      ];
                    }
                  ];
                };

                tasks."sops:decrypt" = {
                  before = [ "devenv:enterShell" ];
                  exec = ''
                    find . -type f -name '*.enc.*' | while read -r enc; do
                      ${getExe pkgs.sops} --decrypt "$enc" > "''${enc%.enc.*}.''${enc##*.enc.}"
                    done
                  '';
                };
              }
            ];

            shells = {
              default = with config.devenv.shells.default.github.lib; {
                imports = [
                  devlib.devenvModules.git
                  devlib.devenvModules.github
                  devlib.devenvModules.nix
                  devlib.devenvModules.opentofu
                  devlib.devenvModules.shell
                  devlib.devenvModules.shikanime
                ];

                github = with config.devenv.shells.default.github.lib; {
                  actions.devenv-test.env.SOPS_AGE_KEY = mkWorkflowRef "secrets.SOPS_AGE_KEY";

                  workflows.release.settings.jobs.publish = with config.devenv.shells.default.github.actions; {
                    permissions = {
                      contents = "read";
                      packages = "write";
                      id-token = "write";
                      attestations = "write";
                    };
                    needs = [
                      "release-branch"
                      "release-tag"
                    ];
                    runs-on = "ubuntu-latest";
                    steps = [
                      create-github-app-token
                      checkout
                      setup-nix
                      cachix-push
                      docker-login
                      {
                        name = "Publish OCI Artifact";
                        env = {
                          GITHUB_SOURCE = mkWorkflowRef "github.event.repository.html_url";
                          GITHUB_REVISION = mkWorkflowRef "github.sha";
                        };
                        run =
                          "skaffold render --profile nishir-tailnet | "
                          + "flux push artifact oci://ghcr.io/shikanime/manifests:latest "
                          + "--path=\"-\" "
                          + "--source=\"$GITHUB_SOURCE\" "
                          + "--revision=\"$GITHUB_REVISION\" "
                          + "--annotations=\"org.opencontainers.image.url=$GITHUB_SOURCE\" "
                          + "--annotations=org.opencontainers.image.vendor=Shikanime "
                          + "--annotations=org.opencontainers.image.title=Manifests "
                          + "--annotations=\"org.opencontainers.image.description=FluxCD Manifests\"";
                      }
                    ];
                  };
                };

                packages = [
                  pkgs.clusterctl
                  pkgs.fluxcd
                  pkgs.k0sctl
                  pkgs.kubectl
                  pkgs.kubernetes-helm
                  pkgs.kustomize
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
                };

                treefmt.config.settings.global.excludes = [
                  "*.excalidraw"
                  "*.enc.xml"
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
