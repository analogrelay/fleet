{ appimageTools, fetchurl, ... }:

let
  pname = "es-de";
  version = "3.1.1";
  src = fetchurl {
    url = "https://gitlab.com/es-de/emulationstation-de/-/package_files/164503027/download";
    hash = "sha256:117k6qixpwvhpydmzky7ir7zsb89ih6a535gf2nzbz2fx8281waf";
  };
  patchUnixFindRules = ./001-add-nixpkgs-retroarch-cores.patch;
  appimageContents = appimageTools.extract {
    inherit pname version src;
    postExtract = ''
        patch $out/usr/share/es-de/resources/systems/unix/es_find_rules.xml < ${patchUnixFindRules}
    '';
  };
in appimageTools.wrapAppImage {
  inherit pname version;
  src = appimageContents;

  extraInstallCommands = ''
    install -m 444 -D ${appimageContents}/usr/share/applications/org.es_de.frontend.desktop $out/share/applications/${pname}.desktop
    install -m 444 -D ${appimageContents}/usr/share/icons/hicolor/scalable/apps/org.es_de.frontend.svg $out/share/icons/hicolor/scalable/apps/org.es_de.frontend.svg
  '';
}