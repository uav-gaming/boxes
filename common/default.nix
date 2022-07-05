# Common configurations

{ lib, pkgs, inputs, ... }:
let
  nixpkgs = if lib.isStorePath pkgs.path then pkgs.path else lib.cleanSource pkgs.path;
in {
  imports = [
    ./ssh-keys
    inputs.impermanence.nixosModule
  ];

  nixpkgs.config.allowUnfree = true;

  nix.nixPath = [
    "nixpkgs=${nixpkgs}"
  ];

  networking.useNetworkd = true;
  services.openssh.enable = true;
  time.timeZone = "America/Los_Angeles";

  environment.systemPackages = with pkgs; [
    vim
    tcpdump
    wget
  ];

  system.stateVersion = "22.05";
}
