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
    };
  };
}