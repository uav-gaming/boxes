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
  boot.kernelParams = [
    "console=ttyS0"
  ];

  systemd.network.networks.enp6s18 = {
    name = "enp6s18";
    networkConfig = {
      DHCP = "yes";
    };
  };

  # console access is trusted
  services.getty.autologinUser = "root";

  services.tailscale.enable = true;
  services.qemuGuest.enable = true;
}

