{
  pkgs,
  pkgs-unstable,
  pkgs-analogrelay,
  platform,
  ...
}:

{
  imports = [ ./${platform}.nix ];

  nix = {
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit pkgs-unstable pkgs-analogrelay;
    };
  };

  programs.zsh.enable = true;

  environment.systemPackages = with pkgs; [
    zsh
    nix
  ];
}
