{
  description = "NixOS Configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vscode-server = {
      url = "github:msteen/nixos-vscode-server";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
    sops-nix.url = "github:Mic92/sops-nix";
    ssh-to-age.url = "github:stephenandary/nix-ssh-to-age";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, ssh-to-age, ... }@inputs :
    let
      overlays = [
      ];
      defaultModules = [
        inputs.sops-nix.nixosModules.sops
        inputs.home-manager.nixosModules.home-manager
      ];
      defaultDarwinModules = [
        inputs.home-manager.darwinModules.home-manager
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
      mkDarwinSystem = system: extraModules:
        inputs.nix-darwin.lib.darwinSystem rec {
          inherit system;
          modules = defaultDarwinModules ++ extraModules;
          specialArgs = { inherit inputs; };
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
      darwinConfigurations = {
        sephiroth = mkDarwinSystem "aarch64-darwin" [
          ./hosts/sephiroth
        ];
      };
    } // flake-utils.lib.eachDefaultSystem (system: 
      let pkgs = nixpkgs.legacyPackages.${system}; in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            ssh-to-age.packages.${system}.ssh-to-age
            pkgs.zsh
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
