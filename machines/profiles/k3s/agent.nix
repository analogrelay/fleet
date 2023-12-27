{ ... }:

{
  imports = 
    [ ./_base.nix
    ];

  services.k3s = {
    role = "agent";
    serverAddr = "https://avalanche.home.analogrelay.net:6443";
  };
}