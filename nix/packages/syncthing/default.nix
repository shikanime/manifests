{ pkgs, ... }:

pkgs.dockerTools.buildImage {
  name = "syncthing";
  tag = "latest";

  config = {
    Cmd = [ "${pkgs.syncthing}/bin/syncthing" ];
    ExposedPorts = {
      "8384/tcp" = {}; # Web UI
      "22000/tcp" = {}; # Transfer protocol
      "21027/udp" = {}; # Discovery broadcasts
    };
    Volumes = {
      "/var/syncthing" = {};
    };
    WorkingDir = "/var/syncthing";
    User = "1000:1000";
  };
}
