{ ... }:

{
    imports = [
        ./nixos.nix
    ];

    home-manager.extraSpecialArgs = {
        wsl = true;
    };

    wsl = {
        enable = true;
        usbip.enable = true;
    };
}