{
  description = "NixOS Configurations";

  inputs = {
    authentik-nix = {
      url = "github:nix-community/authentik-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Temporarily move to release-25.11 until the fix we need moves over to stable
    nixpkgs.url = "github:NixOS/nixpkgs/release-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-analogrelay.url = "github:analogrelay/nixpkgs/analogrelay-main";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
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
      url = "github:LnL7/nix-darwin/nix-darwin-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
    nixos-wsl = {
      url = "github:nix-community/nixos-wsl/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    werx = {
      url = "github:analogrelay/werx";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    jj = {
      url = "github:jj-vcs/jj";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      nixpkgs-analogrelay,
      flake-utils,
      ssh-to-age,
      nix-darwin,
      sops-nix,
      home-manager,
      nix-vscode-extensions,
      nixos-wsl,
      vscode-server,
      werx,
      jj,
      ...
    }@inputs:
    let
      inherit (self) outputs;

      lib = nixpkgs.lib;
      overlays = [
        outputs.overlays.additions
        outputs.overlays.modifications
        werx.overlays.default
        jj.overlays.default
        nix-vscode-extensions.overlays.default
      ];
      defaultNixosModules = [
        inputs.authentik-nix.nixosModules.default
        sops-nix.nixosModules.sops
        home-manager.nixosModules.home-manager
        vscode-server.nixosModule
        ./nix/modules/fleet
        (
          { config, pkgs, ... }:
          {
            services.vscode-server.enable = true;
          }
        )
      ];
      defaultDarwinModules = [
        home-manager.darwinModules.home-manager
        ./nix/modules/fleet
      ];
      mkSpecialArgs =
        system:
        let
          pkgs-unstable = mkPkgsUnstable system;
          pkgs-analogrelay = mkPkgsAnalogrelay system;
        in
        {
          inherit
            inputs
            outputs
            pkgs-unstable
            pkgs-analogrelay
            ;
        };
      mkPkgs =
        system:
        import nixpkgs {
          inherit system overlays;
          config.allowUnfree = true;
        };
      mkPkgsUnstable =
        system:
        import nixpkgs-unstable {
          inherit system overlays;
          config.allowUnfree = true;
        };
      mkPkgsAnalogrelay =
        system:
        import nixpkgs-analogrelay {
          inherit system overlays;
          config.allowUnfree = true;
        };
      mkSystem =
        system: tags: extraModules:
        if tags.platform == "darwin"
        then nix-darwin.lib.darwinSystem {
          pkgs = mkPkgs system;
          modules = defaultDarwinModules ++ extraModules;
          specialArgs = (mkSpecialArgs system) // { inherit tags; };
        }
        else nixpkgs.lib.nixosSystem {
          pkgs = mkPkgs system;
          modules = defaultNixosModules
            ++ lib.optional (tags.platform == "wsl") nixos-wsl.nixosModules.wsl
            ++ extraModules;
          specialArgs = (mkSpecialArgs system) // { inherit tags; };
        };
      mkHome =
        system:
        {
          username,
          role,
          os ? (if builtins.match ".*-darwin" system != null then "darwin" else "linux"),
          wsl ? false,
          realm ? null,
          extraModules ? [ ],
        }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = mkPkgs system;
          extraSpecialArgs = (mkSpecialArgs system) // {
            inherit username;
            tags = {
              inherit os wsl role realm;
              runtime = "bare";
              platform = "standalone";
            };
          };
          modules = [ ./home ] ++ extraModules;
        };
      mkHomes =
        systems: args:
        lib.genAttrs systems (system: mkHome system args);
    in
    rec {
      nixosConfigurations = {
        # Standard x64 servers
        avalanche = mkSystem "x86_64-linux"
          { platform = "nixos"; role = "server"; runtime = "bare"; realm = "analoghome"; admin = "ashley"; identity = "avalanche"; }
          [ ./machines/hosts/avalanche ];
        shinra = mkSystem "x86_64-linux"
          { platform = "nixos"; role = "server"; runtime = "bare"; realm = "analoghome"; admin = "ashley"; identity = "shinra"; }
          [ ./machines/hosts/shinra ];
        scarlet = mkSystem "x86_64-linux"
          { platform = "nixos"; role = "workstation"; runtime = "bare"; realm = "analoghome"; admin = "ashley"; identity = "scarlet"; }
          [ ./machines/hosts/scarlet ];

        # Workstations
        cloud = mkSystem "x86_64-linux"
          { platform = "nixos"; role = "workstation"; runtime = "bare"; realm = "analoghome"; admin = "ashley"; identity = "cloud"; }
          [ ./machines/hosts/cloud ];

        # WSLs
        ashleyst-omegaprime = mkSystem "x86_64-linux"
          { platform = "wsl"; role = "workstation"; runtime = "bare"; realm = "microsoft"; admin = "ashleyst"; identity = "ashleyst-omegaprime"; }
          [ ./machines/hosts/ashleyst-omegaprime ];

        # Live Image
        live = {
          "x86_64" = mkSystem "x86_64-linux"
            { platform = "nixos"; role = "server"; runtime = "bare"; realm = null; admin = "root"; identity = "live"; }
            [ ./machines/images/live ];
        };

        # Container Images
        devenv = mkSystem "x86_64-linux"
          { platform = "nixos"; role = "workstation"; runtime = "container"; realm = null; admin = "ashley"; identity = "devenv"; }
          [ ./machines/images/devenv ];
      };
      darwinConfigurations = {
        # MacBook Workstation
        sephiroth = mkSystem "aarch64-darwin"
          { platform = "darwin"; role = "workstation"; runtime = "bare"; realm = "analoghome"; admin = "ashley"; identity = "sephiroth"; }
          [ ./machines/hosts/sephiroth ];
        tifa = mkSystem "aarch64-darwin"
          { platform = "darwin"; role = "workstation"; runtime = "bare"; realm = "analoghome"; admin = "ashley"; identity = "tifa"; }
          [ ./machines/hosts/tifa ];
      };

      homeConfigurations = {
        # Standalone home-manager configurations for non-NixOS/non-nix-darwin environments
        "ashley@linux-workstation" = mkHomes [ "x86_64-linux" "aarch64-linux" ] {
          username = "ashley";
          role = "workstation";
        };
        "ashley@darwin-workstation" = mkHomes [ "aarch64-darwin" ] {
          username = "ashley";
          role = "workstation";
        };
        "ashley@devcontainer" = mkHomes [ "x86_64-linux" "aarch64-linux" ] {
          username = "ashley";
          role = "workstation";
        };
      };

      overlays = import ./nix/overlays { inherit inputs; };
    }
    // flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        pkgs-unstable = nixpkgs-unstable.legacyPackages.${system};
      in
      {
        packages = import ./nix/pkgs { pkgs = nixpkgs.legacyPackages.${system}; };

        formatter = nixpkgs.legacyPackages.${system}.alejandra;

        devShells.default = pkgs.mkShell {
          packages = [
            home-manager.packages.${system}.home-manager
            pkgs.zsh
            pkgs.bashInteractive
            pkgs.nix
            pkgs.git
            pkgs.jq
            pkgs.uv
            pkgs.python313
          ]
          ++ (pkgs.lib.lists.optional (pkgs.lib.strings.hasSuffix "-darwin" "${system}") [
            nix-darwin.packages.${system}.darwin-rebuild
          ]);

          shellHook = ''
            export FLEET_IN_SHELL=1

            # Prepare Python venv for cloud/sync_inventory
            if [ -d "$PWD/cloud" ]; then
              uv sync --quiet --directory "$PWD/cloud"
              export PATH="$PWD/cloud/.venv/bin:$PATH"
            fi
          '';
        };
      }
    );
}
