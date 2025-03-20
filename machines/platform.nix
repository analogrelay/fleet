{ pkgs, platform, ... }:

{
  imports = [
    ./${platform}.nix
  ];
  
  nix = {
    settings.experimental-features = [ "nix-command" "flakes" ];
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
  };

  programs.zsh.enable = true;

  environment.systemPackages = with pkgs; [
    vim
    git
    wget
    curl
    zsh
    nix-index
    tmux
    nix
    nixpkgs-fmt
    usbutils
    pciutils
    hw-probe
  ];
}
