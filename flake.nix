{
  description = "NixOS Configurations";

  inputs = {
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
      url = "git+ssh://git@github.com/analogrelay/werx";
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

      secretsFile = ./. + "/.secrets.nix";
      secrets = if builtins.pathExists secretsFile then import secretsFile else { };

      lib = nixpkgs.lib;
      overlays = [
        outputs.overlays.additions
        outputs.overlays.modifications
        werx.overlays.default
        jj.overlays.default
        nix-vscode-extensions.overlays.default
      ];
      defaultNixosModules = [
        sops-nix.nixosModules.sops
        home-manager.nixosModules.home-manager
        vscode-server.nixosModule
        (
          { config, pkgs, ... }:
          {
            services.vscode-server.enable = true;
          }
        )
      ];
      defaultDarwinModules = [ home-manager.darwinModules.home-manager ];
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
            secrets
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
          inherit system;
          pkgs = mkPkgs system;
          modules = defaultDarwinModules ++ extraModules;
          specialArgs = (mkSpecialArgs system) // { inherit tags; };
        }
        else nixpkgs.lib.nixosSystem {
          inherit system;
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
    in
    rec {
      nixosConfigurations = {
        # Standard x64 servers
        avalanche = mkSystem "x86_64-linux"
          { platform = "nixos"; role = "server"; runtime = "bare"; realm = "analoghome"; admin = "ashley"; identity = "avalanche"; }
          [ ./machines/hosts/avalanche ];
        shinra = mkSystem "x86_64-linux"
          { platform = "nixos"; role = "workstation"; runtime = "bare"; realm = "analoghome"; admin = "ashley"; identity = "shinra"; }
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
      };

      homeConfigurations = {
        # Standalone home-manager configurations for non-NixOS/non-nix-darwin environments
        "ashley@linux-workstation" = mkHome "x86_64-linux" {
          username = "ashley";
          role = "workstation";
        };
        "ashley@darwin-workstation" = mkHome "aarch64-darwin" {
          username = "ashley";
          role = "workstation";
        };
        "ashley@codespace" = mkHome "x86_64-linux" {
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
            ssh-to-age.packages.${system}.ssh-to-age
            home-manager.packages.${system}.home-manager
            pkgs.zsh
            pkgs.bashInteractive
            pkgs.nix
            pkgs.sops
            pkgs.git
            pkgs.jq
          ]
          ++ (pkgs.lib.lists.optional (pkgs.lib.strings.hasSuffix "-darwin" "${system}") [
            nix-darwin.packages.${system}.darwin-rebuild
          ]);

          shellHook = ''
            export FLEET_IN_SHELL=1
          '';
        };
      }
    );
}
