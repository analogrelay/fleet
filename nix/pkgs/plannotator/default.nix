{ lib, stdenv, fetchurl }:

let
  version = "0.14.4";

  src = {
    "aarch64-darwin" = fetchurl {
      url = "https://github.com/backnotprop/plannotator/releases/download/v${version}/plannotator-darwin-arm64";
      hash = "sha256-/M04a2MG35O5IO0PVzBAEDhLv14C4YePhZ5Wu/0zxxY=";
    };
    "x86_64-darwin" = fetchurl {
      url = "https://github.com/backnotprop/plannotator/releases/download/v${version}/plannotator-darwin-x64";
      hash = "sha256-bYEZ9zBtUSjtBBRhtXXycR0Jl3xwsxoed39IEO9rAtw=";
    };
    "aarch64-linux" = fetchurl {
      url = "https://github.com/backnotprop/plannotator/releases/download/v${version}/plannotator-linux-arm64";
      hash = "sha256-r+NrWCyiPLn3ku0QATDRi5R3vJHfkv1OJ21cZMgWnMY=";
    };
    "x86_64-linux" = fetchurl {
      url = "https://github.com/backnotprop/plannotator/releases/download/v${version}/plannotator-linux-x64";
      hash = "sha256-JLl2th4Pqle7k6py3EaxJ1wWC0IhbSrzLyyuEYKTxI8=";
    };
  }.${stdenv.hostPlatform.system};
in
stdenv.mkDerivation {
  pname = "plannotator";
  inherit version src;

  dontUnpack = true;

  installPhase = ''
    install -Dm755 $src $out/bin/plannotator
  '';

  meta = {
    description = "Plan annotator CLI tool";
    homepage = "https://plannotator.ai";
    platforms = [ "aarch64-darwin" "x86_64-darwin" "aarch64-linux" "x86_64-linux" ];
  };
}
