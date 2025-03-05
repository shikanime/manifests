{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "longhornctl";
  version = "1.8.1";

  src = fetchFromGitHub {
    owner = "longhorn";
    repo = "longhorn-manager";
    rev = "v${version}";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # Replace with actual hash
  };

  vendorHash = ""; # Replace with actual hash

  subPackages = [ "app/cmd/longhornctl" ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/longhorn/longhorn-manager/meta.Version=${version}"
  ];

  meta = with lib; {
    description = "Longhorn command line tool";
    homepage = "https://github.com/longhorn/longhorn-manager";
    license = licenses.asl20;
    maintainers = with maintainers; [ shikanime ];
    mainProgram = "longhornctl";
  };
}