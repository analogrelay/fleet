{ ... }:

{
  programs.ssh = {
    enable = true;
    matchBlocks = {
      "*.node.analogrelay.net" = {
        user = "ashley";
      };
      "*.bicorn-bebop.ts.net" = {
        user = "ashley";
      };
      "github.com" = {
        extraOptions = {
          "StrictHostKeyChecking" = "yes";
        };
      };
      "avalanche.node.analogrelay.net" = {};
      "avalanche.bicorn-bebop.ts.net" = {};
      "shinra.node.analogrelay.net" = {};
      "shinra.bicorn-bebop.ts.net" = {};
      "biggs.node.analogrelay.net" = {};
      "wedge.node.analogrelay.net" = {};
      "tifa.node.analogrelay.net" = {};
      "barret.node.analogrelay.net" = {};
      "zach.node.analogrelay.net" = {
        hostname = "cloud.node.analogrelay.net";
        port = 2222;
      };
      "zach.bicorn-bebop.ts.net" = {
        hostname = "cloud.bicorn-bebop.ts.net";
        port = 2222;
      };
    };
  };
}