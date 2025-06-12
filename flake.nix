{
  description = "NixOS Configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-analogrelay.url = "github:analogrelay/nixpkgs/analogrelay-main";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    mac-app-util.url = "github:hraban/mac-app-util";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
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
      url = "github:LnL7/nix-darwin/nix-darwin-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/2405.5.4";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, nixpkgs-analogrelay
    , nixos-hardware, flake-utils, ssh-to-age, nix-darwin, sops-nix
    , home-manager, mac-app-util, nix-vscode-extensions, nixos-wsl
    , vscode-server, ... }@inputs:
    let
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
        ({ config, pkgs, ... }: { services.vscode-server.enable = true; })
      ];
      defaultDarwinModules = [ home-manager.darwinModules.home-manager ];
      mkSpecialArgs = system: platform:
        let
          pkgs-unstable = mkPkgsUnstable system;
          pkgs-analogrelay = mkPkgsAnalogrelay system;
        in { inherit inputs outputs platform pkgs-unstable pkgs-analogrelay; };
      mkPkgs = system:
        import nixpkgs {
          inherit system overlays;
          config.allowUnfree = true;
        };
      mkPkgsUnstable = system:
        import nixpkgs-unstable {
          inherit system overlays;
          config.allowUnfree = true;
        };
      mkPkgsAnalogrelay = system:
        import nixpkgs-analogrelay {
          inherit system overlays;
          config.allowUnfree = true;
        };
      mkSystem = system: extraModules:
        nixpkgs.lib.nixosSystem rec {
          inherit system;
          pkgs = mkPkgs system;
          modules = defaultModules ++ extraModules;
          specialArgs = mkSpecialArgs system "nixos";
        };
      mkWslSystem = system: extraModules:
        nixpkgs.lib.nixosSystem rec {
          inherit system;
          pkgs = mkPkgs system;
          modules = defaultModules ++ [ nixos-wsl.nixosModules.wsl ]
            ++ extraModules;
          specialArgs = mkSpecialArgs system "wsl";
        };
      mkDarwinSystem = system: extraModules:
        nix-darwin.lib.darwinSystem rec {
          inherit system;
          pkgs = mkPkgs system;
          modules = defaultDarwinModules ++ extraModules;
          specialArgs = mkSpecialArgs system "darwin";
        };
    in rec {
      lib = { inherit mkSystem; };

      nixosConfigurations = {
        # Standard x64 servers
        avalanche = mkSystem "x86_64-linux" [ ./machines/hosts/avalanche ];
        shinra = mkSystem "x86_64-linux" [ ./machines/hosts/shinra ];
        scarlet = mkSystem "x86_64-linux" [ ./machines/hosts/scarlet ];

        # Workstations
        cloud = mkSystem "x86_64-linux" [ ./machines/hosts/cloud ];

        # WSLs
        zach = mkWslSystem "x86_64-linux" [ ./machines/hosts/zach ];
        ashleyst-alphaprime =
          mkWslSystem "x86_64-linux" [ ./machines/hosts/ashleyst-alphaprime ];

        # Raspberry Pis
        jessie = mkSystem "aarch64-linux" [ ./machines/hosts/jessie ];
        wedge = mkSystem "aarch64-linux" [ ./machines/hosts/wedge ];

        # Live Image
        live = {
          "x86_64" = mkSystem "x86_64-linux" [ ./machines/images/live ];
        };
      };
      darwinConfigurations = {
        # MacBook Workstation
        sephiroth =
          mkDarwinSystem "aarch64-darwin" [ ./machines/hosts/sephiroth ];
      };

      homeConfigurations = {
        "ashley@zach" = home-manager.lib.homeManagerConfiguration {
          pkgs = mkPkgs "x86_64-linux";
          extraSpecialArgs = {
            username = "ashley";
            os = "linux";
            distro = "fedora";
            role = "workstation";
            wsl = false;
            realm = "analoghome";
          };
          modules = [ ./home ];
        };
        "ashleyst@ashleyst-delta" = home-manager.lib.homeManagerConfiguration {
          pkgs = mkPkgs "x86_64-linux";
          extraSpecialArgs = {
            username = "ashleyst";
            os = "linux";
            distro = "ubuntu";
            role = "workstation";
            wsl = true;
            realm = "microsoft";
          };
          modules = [ ./home ];
        };
      };

      overlays = import ./overlays { inherit inputs; };
    } // flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        pkgs-unstable = nixpkgs-unstable.legacyPackages.${system};
      in {
        packages = import ./pkgs { pkgs = nixpkgs.legacyPackages.${system}; };

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
            pkgs.python3
            pkgs.yq
          ] ++ (pkgs.lib.lists.optional
            (pkgs.lib.strings.hasSuffix "-darwin" "${system}")
            [ nix-darwin.packages.${system}.darwin-rebuild ]);

          shellHook = ''
            export FLEET_IN_SHELL=1
            python -m venv .venv --copies
            source .venv/bin/activate
            pip install -r requirements.txt
          '';
        };
      });
}
