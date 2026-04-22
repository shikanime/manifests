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
                  settings =
                    let
                      keyGroups = [
                        {
                          age = [
                            "age1045knj0kzudt68plt0snrhp7u0gffp2uh8ul4g6qy93nel5rw4wq3ag2kl" # kaltashar
                            "age17q5ljstyzkvqtejwfnyf5jvqduars2yauw7vtgu5fcf54tm2jf0sspvt3c" # telsha
                            "age1dnxv9pweev9aqm5d6a8ylnw2z3tjds2hed5j73awtqmyr0cy354q068md4" # github
                            "age1a9vtmpe385n3f9nd6dxxjgcvhccc0apu22jsvwwd2d7ej82nq3tq8hwggy" # nishir
                            "age1x9v4ps90txy9mk4392uya93tyzx40te4dvns4chg5s6q8mfy03ns74jpay" # nixtar
                            "age1lcz72z6vkjywvhth955l5q9fl5wu8sdf32jpy2y6tz3rers7v5tq2gz7tx" # telsha
                          ];
                        }
                      ];
                    in
                    {
                      creation_rules = [
                        {
                          path_regex = "apps/bazarr/overlays/.*/bazarr/config\\..*";
                          encrypted_regex = "^(apikey|api_key|password|token|cookies|passkey|flask_secret_key|encryption_key|hashed_password|anti_captcha_key|gemini_key)$";
                          key_groups = keyGroups;
                        }
                        {
                          path_regex = "apps/forgejo/overlays/.*/forgejo/app\\..*";
                          encrypted_regex = "^(PASSWD|SECRET_KEY|INTERNAL_TOKEN|LFS_JWT_SECRET|JWT_SECRET|PASSWORD|PROVIDER_CONFIG)$";
                          key_groups = keyGroups;
                        }
                        {
                          path_regex = "apps/synapse/overlays/.*/synapse/homeserver\\..*";
                          encrypted_regex = "^(registration_shared_secret|form_secret|macaroon_secret_key)$";
                          key_groups = keyGroups;
                        }
                        {
                          path_regex = "apps/mautrix/.*/overlays/.*/matrix-.*/config\\..*";
                          encrypted_regex = "^(avatar_proxy_key|as_token|hs_token|pickle_key|server_key|shared_secret|signing_key|login_shared_secret_map|secrets)$";
                          key_groups = keyGroups;
                        }
                        {
                          path_regex = "apps/mautrix/.*/overlays/.*/matrix-.*/(registration|doublepuppet)\\..*";
                          encrypted_regex = "^(as_token|hs_token)$";
                          key_groups = keyGroups;
                        }
                        {
                          key_groups = keyGroups;
                        }
                      ];
                    };
                };
              }
            ];

            shells = {
              default = {
                imports = [
                  devlib.devenvModules.git
                  devlib.devenvModules.nix
                  devlib.devenvModules.opentofu
                  devlib.devenvModules.shell
                  devlib.devenvModules.shikanime
                ];

                github.workflows.skaffold.enable = true;

                packages = [
                  pkgs.age
                  pkgs.caddy
                  pkgs.clusterctl
                  pkgs.docker
                  pkgs.fluxcd
                  pkgs.fluxcd-operator
                  pkgs.gatekeeper
                  pkgs.k0sctl
                  pkgs.kubectl
                  pkgs.kubernetes-helm
                  pkgs.kustomize
                  pkgs.skaffold
                ];

                tasks = {
                  "bootstrap:nishir".exec = ''
                    ${getExe pkgs.k0sctl} apply \
                      --config $DEVENV_ROOT/bootstraps/nishir/cluster.yaml

                    KUBECONFIG=$(mktemp)
                    ${getExe pkgs.k0sctl} kubeconfig \
                      --config $DEVENV_ROOT/bootstraps/nishir/cluster.yaml > "$KUBECONFIG"

                    ${getExe pkgs.kubectl} \
                      --kubeconfig "$KUBECONFIG" wait \
                      --for=create namespace/flux-system

                    if ! ${getExe pkgs.kubectl} -n flux-system get secret sops-age >/dev/null 2>&1; then
                      ${getExe' pkgs.age "age-keygen"} | ${getExe pkgs.kubectl} \
                        --kubeconfig "$KUBECONFIG" \
                        --namespace flux-system \
                        create secret generic sops-age \
                        --from-file=age.agekey=/dev/stdin
                    fi
                  '';
                  "bootstrap:telsha".exec = ''
                    ${getExe pkgs.kubectl} apply -k $DEVENV_ROOT/bootstraps/telsha

                    if ! ${getExe pkgs.kubectl} -n flux-system get secret sops-age >/dev/null 2>&1; then
                      ${getExe' pkgs.age "age-keygen"} | ${getExe pkgs.kubectl} \
                        -n flux-system \
                        create secret generic sops-age \
                        --from-file=age.agekey=/dev/stdin
                    fi
                  '';
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
        "aarch64-linux"
        "aarch64-darwin"
      ];
    };
}
