{ ... }:

{
  imports = 
    [ ./_base.nix
    ];

  services.k3s = {
    role = "agent";
    serverAddr = "https://avalanche.node.analogrelay.net:6443";
  };
}