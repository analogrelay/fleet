{ pkgs, ... }:

{
    services.xserver.enable = true;
    services.displayManager.sddm.enable = true;
    services.desktopManager.plasma6.enable = true;

    environment.systemPackages = [
        pkgs.appimage-run
        pkgs.kdePackages.krdp
    ];

    services.xrdp = {
        enable = true;
        defaultWindowManager = "startplasma-x11";
        openFirewall = true;
    };

    boot.binfmt.registrations.appimage = {
        wrapInterpreterInShell = false;
        interpreter = "${pkgs.appimage-run}/bin/appimage-run";
        recognitionType = "magic";
        offset = 0;
        mask = ''\xff\xff\xff\xff\x00\x00\x00\x00\xff\xff\xff'';
        magicOrExtension = ''\x7fELF....AI\x02'';
    };
}