{ pkgs, role, ... }:

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "*.node.analogrelay.net" = {
        forwardAgent = true;
        user = "ashley";
      };
      "*.bicorn-bebop.ts.net" = {
        forwardAgent = true;
        user = "ashley";
      };
      "*.internal.analogrelay.cloud" = {
        user = "azureuser";
        proxyJump = "analogrelay.cloud";
        forwardAgent = true;
      };
      "*.analogrelay.cloud" = {
        forwardAgent = true;
        user = "azureuser";
      };
      "analogrelay.cloud" = {
        forwardAgent = true;
        user = "azureuser";
      };
      "gaia.node.analogrelay.net" = { user = "admin"; };
      "avalanche.node.analogrelay.net" = { };
      "avalanche.bicorn-bebop.ts.net" = { };
      "cloud.node.analogrelay.net" = { };
      "cloud.bicorn-bebop.ts.net" = { };
      "scarlet.node.analogrelay.net" = { };
      "scarlet.bicorn-bebop.ts.net" = { };
      "shinra.node.analogrelay.net" = { };
      "shinra.bicorn-bebop.ts.net" = { };
      "biggs.node.analogrelay.net" = { };
      "wedge.node.analogrelay.net" = { };
      "tifa.node.analogrelay.net" = { };
      "barret.node.analogrelay.net" = { };
      "zach.node.analogrelay.net" = {
        hostname = "cloud.node.analogrelay.net";
        port = 2222;
      };
      "zach.bicorn-bebop.ts.net" = {
        hostname = "cloud.bicorn-bebop.ts.net";
        port = 2222;
      };

      # The TP-Link Access Points use ssh-rsa host keys
      "wutai.node.analogrelay.net" = {
        extraOptions = {
          "PubkeyAcceptedAlgorithms" = "+ssh-rsa";
          "HostkeyAlgorithms" = "+ssh-rsa";
        };
      };
      "midgar.node.analogrelay.net" = {
        extraOptions = {
          "PubkeyAcceptedAlgorithms" = "+ssh-rsa";
          "HostkeyAlgorithms" = "+ssh-rsa";
        };
      };
    };
  };
}
