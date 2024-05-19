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
    ssh-to-age.url = "github:Mic92/ssh-to-age";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
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
    nixos-wsl,
    vscode-server,
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
        vscode-server.nixosModule
        ({config, pkgs, ...}: {services.vscode-server.enable = true;})
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
      mkWslSystem = system: extraModules:
        nixpkgs.lib.nixosSystem rec {
          inherit system;
          pkgs = mkPkgs system;
          modules = defaultModules ++ [
            nixos-wsl.nixosModules.wsl
          ] ++ extraModules;
          specialArgs = {inherit inputs outputs; platform = "wsl"; };
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
          pkgs = mkPkgs system;
          modules = [
            "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
            { sdImage.compressImage = false; }
          ] ++ defaultModules ++ extraModules;
          specialArgs = {inherit inputs outputs; platform = "nixos"; };
        };
    in
    rec {
      lib = { inherit mkSystem; };

      nixosConfigurations = {
        avalanche = mkSystem "x86_64-linux" [ ./machines/hosts/avalanche ];
        shinra = mkSystem "x86_64-linux" [ ./machines/hosts/shinra ];
        biggs = mkImage "aarch64-linux" [ ./machines/hosts/biggs ];
        zach = mkWslSystem "x86_64-linux" [ ./machines/hosts/zach ];
      };
      darwinConfigurations = {
        sephiroth = mkDarwinSystem "aarch64-darwin" [
          ./machines/hosts/sephiroth
        ];
      };

      homeConfigurations = {
        "ashleyst@ashleyst-delta" = home-manager.lib.homeManagerConfiguration {
          pkgs = mkPkgs "x86_64-linux";
          extraSpecialArgs = {
            username = "ashleyst";
            os = "linux";
            distro = "ubuntu";
            role = "workstation";
            wsl = true;
          };
          modules = [
            ./home
          ];
        };
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
            pkgs.nodejs
            pkgs-unstable.pulumi-bin
          ] ++ (pkgs.lib.lists.optional (pkgs.lib.strings.hasSuffix "-darwin" "${system}") [
            nix-darwin.packages.${system}.darwin-rebuild
          ]);

          shellHook = ''
            export FLEET_IN_SHELL=1
          '';
      };
    });
}
