{ lib, isDarwin, isWsl, pkgs, pkgs-unstable, pkgs-analogrelay, ... }:

{
  imports = [
    ./fleet.nix
    ./roles/server.nix
    ./roles/workstation.nix
    ./realms/analoghome.nix
    ./realms/microsoft.nix
  ]
  ++ lib.optionals isDarwin [
    ./darwin.nix
  ]
  ++ lib.optionals (!isDarwin) [
    ./nixos.nix
    ./roles/server.nixos.nix
    ./roles/workstation.nixos.nix
    ./realms/analoghome.nixos.nix
  ]
  ++ lib.optionals isWsl [
    ./wsl.nix
    ./roles/workstation.wsl.nix
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

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
