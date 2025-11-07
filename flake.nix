{
  inputs = {
    devenv.url = "github:cachix/devenv";
    devlib.url = "github:shikanime-studio/devlib";
    flake-parts.url = "github:hercules-ci/flake-parts";
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
      treefmt-nix,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        devenv.flakeModule
        treefmt-nix.flakeModule
      ];
      perSystem =
        { self', pkgs, ... }:
        {
          treefmt = {
            projectRootFile = "flake.nix";
            enableDefaultExcludes = true;
            programs = {
              gofmt.enable = true;
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
          devenv = {
            modules = [
              devlib.devenvModule
            ];
            shells = {
              default = {
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
                  go.enable = true;
                  nix.enable = true;
                  opentofu.enable = true;
                };
                packages = [
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
                  self'.packages.longhornctl
                ];
              };
              update = {
                containers = pkgs.lib.mkForce { };
                packages = [
                  pkgs.gh
                  pkgs.sapling
                ];
              };
            };
          };
          packages.longhornctl = pkgs.buildGoModule rec {
            pname = "longhornctl";
            version = "1.10.0";

            src = pkgs.fetchFromGitHub {
              owner = "longhorn";
              repo = "cli";
              rev = "v${version}";
              hash = "sha256-5wvdVgc6YlzxNEyLckyg6h+gwxGGLMhseT1o3tuvC6s=";
            };

            vendorHash = null;

            subPackages = [ "cmd/remote" ];

            ldflags = [
              "-s"
              "-w"
              "-X github.com/longhorn/cli/meta.Version=v${version}"
              "-X github.com/longhorn/cli/meta.GitCommit=${src.rev}"
              "-X github.com/longhorn/cli/meta.BuildDate=1970-01-01T00:00:00+00:00"
            ];

            postInstall = ''
              mv $out/bin/remote $out/bin/longhornctl
            '';

            meta = with pkgs.lib; {
              description = "Longhorn command line tool";
              homepage = "https://github.com/longhorn/cli";
              license = licenses.asl20;
              maintainers = with maintainers; [ shikanime ];
              mainProgram = "longhornctl";
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
