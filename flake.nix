{
  description = "NixOS Configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    mac-app-util.url = "github:hraban/mac-app-util";
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
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
  };

  outputs = { 
    self, 
    nixpkgs, 
    nixpkgs-unstable, 
    flake-utils, 
    ssh-to-age, 
    nix-darwin, 
    sops-nix, 
    home-manager, 
    mac-app-util, 
    nix-vscode-extensions,
    ... }@inputs: let
      inherit (self) outputs;

      overlays = [
        outputs.overlays.additions
        outputs.overlays.modifications
        nix-vscode-extensions.overlays.default
      ];
      defaultModules = [
        sops-nix.nixosModules.sops
        home-manager.nixosModules.home-manager
      ];
      defaultDarwinModules = [
        home-manager.darwinModules.home-manager
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
          specialArgs = {inherit inputs outputs; platform = "nixos"; };
        };
      mkDarwinSystem = system: extraModules:
        nix-darwin.lib.darwinSystem rec {
          inherit system;
          pkgs = mkPkgs system;
          modules = defaultDarwinModules ++ extraModules;
          specialArgs = { inherit inputs outputs; platform = "darwin"; };
        };
      mkImage = system: extraModules:
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules = defaultModules ++ extraModules;
          specialArgs = {inherit inputs outputs; platform = "nixos"; };
        };
    in
    rec {
      lib = { inherit mkSystem; };

      nixosConfigurations = {
        avalanche = mkSystem "x86_64-linux" [
          ./machines/hosts/avalanche
          inputs.vscode-server.nixosModule
          ({config, pkgs, ...}: {services.vscode-server.enable = true;})
        ];
        shinra = mkSystem "x86_64-linux" [
          ./machines/hosts/shinra
          inputs.vscode-server.nixosModule
          ({config, pkgs, ...}: {services.vscode-server.enable = true;})
        ];
        rpi4 = mkImage "aarch64-linux" [
          "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
          {
            nixpkgs.config.allowUnsupportedSystem = true;
            nixpkgs.hostPlatform.system = "aarch64-linux";
            nixpkgs.buildPlatform.system = "x86_64-linux";
          }
          ./machines/images/rpi4
        ];
      };
      darwinConfigurations = {
        sephiroth = mkDarwinSystem "aarch64-darwin" [
          ./machines/hosts/sephiroth
        ];
      };

      images = {
        rpi4 = nixosConfigurations.rpi4.config.system.build.sdImage;
      };

      overlays = import ./overlays {inherit inputs;};
    } // flake-utils.lib.eachDefaultSystem (system: 
      let 
        pkgs = nixpkgs.legacyPackages.${system};
        pkgs-unstable = nixpkgs-unstable.legacyPackages.${system};
      in
      {
        packages = import ./pkgs {pkgs = nixpkgs.legacyPackages.${system}; };

        formatter = nixpkgs.legacyPackages.${system}.alejandra;

        devShells.default = pkgs.mkShell {
          packages = [
            ssh-to-age.packages.${system}.ssh-to-age
            pkgs.zsh
            pkgs.bashInteractive
            pkgs.nix
            pkgs.sops
            pkgs.git
            pkgs.jq
          ] ++ (pkgs.lib.lists.optional (pkgs.lib.strings.hasSuffix "-darwin" "${system}") [
            nix-darwin.packages.${system}.darwin-rebuild
          ]);

          shellHook = ''
            export FLEET_IN_SHELL=1
          '';
      };
    });
}
