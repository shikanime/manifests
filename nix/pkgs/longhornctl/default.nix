{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule rec {
  pname = "longhornctl";
  version = "1.8.0";

  src = fetchFromGitHub {
    owner = "longhorn";
    repo = "cli";
    rev = "v${version}";
    hash = "sha256-b4baSLYsibdhEgOPbgZxD5M63rdSiztofmB73JPvY4E=";
  };

  vendorHash = null;

  subPackages = [ "cmd/remote" ];

  postInstall = ''
    mv $out/bin/remote $out/bin/longhornctl
  '';

  meta = with lib; {
    description = "Longhorn command line tool";
    homepage = "https://github.com/longhorn/cli";
    license = licenses.asl20;
    maintainers = with maintainers; [ shikanime ];
    mainProgram = "longhornctl";
  };
}
