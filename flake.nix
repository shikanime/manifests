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
              automata.packages.${system}.default
            ];
            treefmt = {
              config = {
                enableDefaultExcludes = true;
                programs.prettier.enable = true;
                settings.global.excludes = [
                  "*.excalidraw"
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
