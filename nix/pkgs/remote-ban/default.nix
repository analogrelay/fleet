{ lib, stdenv, makeWrapper, openssh }:

let
  # Reference the server script directly so we can install an
  # un-patched portable copy for deployment to non-NixOS hosts.
  serverScript = ./remote-ban-server.sh;
in
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
      --prefix PATH : ${lib.makeBinPath [ openssh ]} \
      --set REMOTE_BAN_SERVER_SCRIPT $out/share/remote-ban/remote-ban-server

    runHook postInstall
  '';

  # Install a portable copy with the original #!/usr/bin/env bash shebang
  # (patchShebangs in fixupPhase rewrites $out/bin/ shebangs to Nix store paths).
  # The client's `install` subcommand deploys this copy to remote hosts.
  postFixup = ''
    install -Dm755 ${serverScript} $out/share/remote-ban/remote-ban-server
  '';

  meta = {
    description = "Remote IP ban management via SSH and iptables";
    platforms = lib.platforms.linux;
  };
}
