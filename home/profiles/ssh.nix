{ ... }:

{
  programs.ssh = {
    enable = true;
    matchBlocks = {
      "*.home.analogrelay.net" = {
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
      "avalanche.home.analogrelay.net" = {};
      "avalanche.bicorn-bebop.ts.net" = {};
      "shinra.home.analogrelay.net" = {};
      "shinra.bicorn-bebop.ts.net" = {};
    };
  };
}