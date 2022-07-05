{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";

    nix-minecraft.url = "github:Infinidoge/nix-minecraft";
    nixos-shell.url = "github:Mic92/nixos-shell";

    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, utils, nix-minecraft, nixos-shell, ... }: {
    colmena = {
      meta = {
        description = "UAV Gaming";
        nixpkgs = import nixpkgs {
          system = "x86_64-linux";
          overlays = [
            nix-minecraft.overlay
          ];
        };
      };

      defaults = import ./common;

      bedrock = import ./hosts/bedrock;
    };

    # Launch VM with ./launch-vm.sh
    nixosConfigurations.bedrock-mini = nixpkgs.lib.makeOverridable nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./common
        ./hosts/bedrock/minecraft.nix
        nixos-shell.nixosModules.nixos-shell
        ({ lib, ... }: {
          networking.hostName = "bedrock-mini";
          nixpkgs.overlays = [ nix-minecraft.overlay ];

          services.getty.helpLine = lib.mkForce ''
            Log in as "root" with an empty password.

            Minecraft: Connect to the server at "localhost".
          '';

          virtualisation = {
            cores = 4;
            diskSize = 2048;
            memorySize = 4096;
            forwardPorts = [
              {
                from = "host";
                proto = "tcp";
                host.port = 25565;
                guest.port = 25565;
              }
            ];
          };
        })
      ];
    };
  } // utils.lib.eachDefaultSystem (system: let
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    devShell = pkgs.mkShell {
      packages = with pkgs; [
        act
        colmena
        nixos-shell.defaultPackage.${system}
      ];
    };
  });
}
