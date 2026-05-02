{ pkgs, fetchFromGitHub, ... }:

pkgs.buildGoModule {
  pname = "shelly-exporter";
  version = "0.2.6";
  src = fetchFromGitHub {
    owner = "analogrelay";
    repo = "shelly_exporter";
    rev = "f1feebf50590e3ace622a59be50207991948a45f";
    hash = "sha256-76/BLJNUpeJFFVD9oL+jpWF/vsMWqA5S6W2YMPJFvOc=";
  };

  vendorHash = "sha256-Dk16vWkM5ovFjhXNyxd7lTP0OVKbsj1SM7zFzkFwdL0=";

  postInstall = ''
    mv $out/bin/exporter $out/bin/shelly-exporter
  '';

  meta = with pkgs.lib; {
    description = "Prometheus Exporter for Shelly Smart Home Devices";
    homepage = "https://github.com/Supporterino/shelly_exporter";
    license = licenses.gpl3;
    mainProgram = "shelly-exporter";
  };
}
