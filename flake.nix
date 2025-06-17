{
  inputs = {
    devenv.url = "github:cachix/devenv";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  nixConfig = {
    extra-public-keys = [
      "shikanime.cachix.org-1:OrpjVTH6RzYf2R97IqcTWdLRejF6+XbpFNNZJxKG8Ts="
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
    ];
    extra-substituters = [
      "https://shikanime.cachix.org"
      "https://devenv.cachix.org"
    ];
  };

  outputs =
    inputs@{
      devenv,
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
              opentofu.enable = true;
              nix.enable = true;
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
              tflint.enable = true;
            };
            packages = [
              pkgs.clusterctl
              pkgs.gh
              pkgs.gitnr
              pkgs.gnugrep
              pkgs.gnused
              pkgs.kubectl
              pkgs.kubernetes-helm
              pkgs.kustomize
              pkgs.skaffold
              pkgs.skopeo
              pkgs.yq-go
              self'.packages.longhornctl
            ];
          };
          packages.longhornctl = pkgs.buildGoModule rec {
            pname = "longhornctl";
            version = "1.8.1";

            src = pkgs.fetchFromGitHub {
              owner = "longhorn";
              repo = "cli";
              rev = "v${version}";
              hash = "sha256-b4baSLYsibdhEgOPbgZxD5M63rdSiztofmB73JPvY4E=";
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
