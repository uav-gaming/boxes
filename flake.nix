{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";

    nix-minecraft.url = "github:Infinidoge/nix-minecraft";

    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, utils, nix-minecraft, ... }: {
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
  } // utils.lib.eachDefaultSystem (system: let
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    devShell = pkgs.mkShell {
      packages = with pkgs; [
        act
        colmena
      ];
    };
  });
}
