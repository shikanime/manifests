{
  perSystem =
    { self', pkgs, ... }:
    {
      packages = {
        longhornctl = pkgs.callPackage ../../packages/longhornctl { };
        syncthing = pkgs.callPackage ../../packages/syncthing { };
      };
    };
}
