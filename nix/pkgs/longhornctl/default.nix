{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule rec {
  pname = "longhornctl";
  version = "1.8.1";

  src = fetchFromGitHub {
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
    "-X github.com/longhorn/cli/meta.Version=${version}"
    "-X github.com/longhorn/cli/meta.GitCommit=${src.rev}"
    "-X github.com/longhorn/cli/meta.BuildDate=2025-03-08T15:00:05+00:00"
  ];

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
