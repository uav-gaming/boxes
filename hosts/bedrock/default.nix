# Minecraft

{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./minecraft.nix
    ./persistence.nix
  ];

  deployment.targetHost = "100.70.137.13";

  networking.hostName = "bedrock";
  networking.hostId = "abcd1234";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.zfs.devNodes = "/dev/disk/by-path";

  systemd.network.networks.enp1s0 = {
    name = "enp1s0";
    networkConfig = {
      DHCP = "yes";
    };
    address = [ "172.20.16.83/28" ];
    gateway = [ "172.20.16.81" ];
  };

  # console access is trusted
  services.getty.autologinUser = "root";

  services.tailscale.enable = true;
}

