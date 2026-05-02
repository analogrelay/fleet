{ lib, stdenv, makeWrapper, openssh }:

stdenv.mkDerivation {
  pname = "remote-ban";
  version = "0.1.0";

  src = ./.;

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 remote-ban.sh $out/bin/remote-ban
    install -Dm755 remote-ban-server.sh $out/bin/remote-ban-server

    wrapProgram $out/bin/remote-ban \
      --prefix PATH : ${lib.makeBinPath [ openssh ]}

    runHook postInstall
  '';

  meta = {
    description = "Remote IP ban management via SSH and iptables";
    platforms = lib.platforms.linux;
  };
}
