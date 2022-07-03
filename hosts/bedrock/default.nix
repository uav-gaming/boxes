# Minecraft

{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./minecraft.nix
  ];

  deployment.targetHost = "100.70.137.13";

  networking.hostName = "bedrock";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  systemd.network.networks.enp1s0 = {
    name = "enp1s0";
    networkConfig = {
      DHCP = "yes";
    };
    address = [ "172.20.16.83/28" ];
    gateway = [ "172.20.16.81" ];
  };

  services.tailscale.enable = true;
}

