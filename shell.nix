{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  buildInputs = [
    pkgs.skaffold
    pkgs.kustomize
  ];
}
