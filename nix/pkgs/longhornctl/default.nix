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
    hash = "sha256-cggdc/ibeSabGVCZdZEQqeHbl77OrN9lHMvTWWYxZ74=";
  };

  vendorHash = "";

  subPackages = [ "app/cmd/longhornctl" ];

  meta = with lib; {
    description = "Longhorn command line tool";
    homepage = "https://github.com/longhorn/cli";
    license = licenses.asl20;
    maintainers = with maintainers; [ shikanime ];
    mainProgram = "longhornctl";
  };
}