{
  description = "NixOS Configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vscode-server = {
      url = "github:msteen/nixos-vscode-server";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix.url = "github:Mic92/sops-nix";
  };

  outputs = { self, nixpkgs, ... }@inputs :
    let
      overlays = [
      ];
      defaultModules = [
        inputs.sops-nix.nixosModules.sops
      ];
      mkPkgs = system:
        import nixpkgs {
          inherit system overlays;
          config.allowUnfree = true;
        };
      mkSystem = system: extraModules:
        nixpkgs.lib.nixosSystem rec {
          inherit system;
          pkgs = mkPkgs system;
          modules = defaultModules ++ extraModules;
        };
    in
    {
      inherit overlays;
      lib = { inherit mkSystem; };

      nixosConfigurations = {
        avalanche = mkSystem "x86_64-linux" [
          ./hosts/avalanche
          inputs.vscode-server.nixosModule
          ({config, pkgs, ...}: {services.vscode-server.enable = true;})
        ];
        shinra = mkSystem "x86_64-linux" [
          ./hosts/shinra
          inputs.vscode-server.nixosModule
          ({config, pkgs, ...}: {services.vscode-server.enable = true;})
        ];
      };
    };
}
