# Based on https://github.com/NixOS/nixpkgs/blob/master/pkgs/applications/networking/browsers/microsoft-edge/browser.nix
# But for macOS

{ channel, version, uuid, hash } :

{ stdenv
, fetchurl
, lib

, xar
, cpio

, ... }: let
  baseName = "microsoft-edge";
  shortName = if channel == "stable"
              then "msedge"
              else "msedge-" + channel;
  longName = if channel == "stable"
             then baseName
             else baseName + "-" + channel;
  iconSuffix = lib.optionalString (channel != "stable") "_${channel}";
  desktopSuffix = lib.optionalString (channel != "stable") "-${channel}";
in
stdenv.mkDerivation rec {
    pname = "${baseName}-${channel}";
    inherit version;

    src = fetchurl {
        url = "https://msedge.sf.dl.delivery.mp.microsoft.com/filestreamingservice/files/${uuid}/MicrosoftEdge-${version}.pkg";
        inherit hash;
        postFetch = ''
            unpack_dir="$TMPDIR/unpack"
            mkdir "$unpack_dir"
            cd "$unpack_dir"

            xar -xf "$downloadedFile"
        '';
    };

    buildInputs = [
        xar
        cpio
    ];

    unpackCmd = "${./unpkg.sh} \"$curSrc\" \"MicrosoftEdge-${version}.pkg\"";
    sourceRoot = "content";

    installPhase = ''
        mkdir -p $out/Applications
        cp -r *.app $out/Applications
    '';

    dontFixup = true;

    meta = {
        homepage = https://www.microsoft.com/en-us/edge;
        description = "Microsoft Edge Browser";
        platforms = [ "aarch64-darwin" ];
    };
}