{ pkgs, ... }:

{
    services.xserver.enable = true;
    services.displayManager.sddm.enable = true;
    services.desktopManager.plasma6.enable = true;

    environment.systemPackages = [
        pkgs.kdePackages.krdp
    ];

    services.xrdp = {
        enable = true;
        defaultWindowManager = "startplasma-x11";
        openFirewall = true;
    };
}