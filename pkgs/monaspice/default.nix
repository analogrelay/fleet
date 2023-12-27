{ stdenvNoCC
, fetchzip
, ... }: stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "monaspice";
  version = "3.1.1";

  src = fetchzip {
    url = "https://github.com/ryanoasis/nerd-fonts/releases/download/v${finalAttrs.version}/Monaspace.zip";
    stripRoot = false;
    hash = "sha256-tvlXseoScqB6rlzWaqArLd7n1i1+uElywmMoxZTIdoI=";
  };

  installPhase = ''
    runHook preInstall

    install -Dm644 *.otf -t $out/share/fonts/opentype

    runHook postInstall
  '';
})