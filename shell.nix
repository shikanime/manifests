{ pkgs ? import <nixpkgs> { } }:

pkgs.stdenv.mkDerivation {
  name = "nishir-shell";
  buildInputs = [
    pkgs.kubectl
    pkgs.kubernetes-helm
  ];
}
