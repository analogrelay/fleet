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
    flake-utils.url = "github:numtide/flake-utils";
    sops-nix.url = "github:Mic92/sops-nix";
    ssh-to-age.url = "github:stephenandary/nix-ssh-to-age";
  };

  outputs = { self, nixpkgs, flake-utils, ssh-to-age, ... }@inputs :
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
    } // flake-utils.lib.eachDefaultSystem (system: 
      let pkgs = nixpkgs.legacyPackages.${system}; in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            ssh-to-age.packages.${system}.ssh-to-age
            pkgs.bashInteractive
            pkgs.nix
            pkgs.sops
            pkgs.yq
          ];

          shellHook = ''
            export FLEET_IN_SHELL=1
          '';
      };
    });
}
