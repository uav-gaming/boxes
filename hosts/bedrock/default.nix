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

  environment.systemPackages = with pkgs; [
    libwebp
  ];

  # console access is trusted
  services.getty.autologinUser = "root";

  services.tailscale.enable = true;
  services.qemuGuest.enable = true;

  security.acme = {
    acceptTerms = true;
    defaults.email = "uav@tjhu.dev";
    certs."uav-gaming.eu.org" = {
      dnsProvider = "cloudflare";
      extraDomainNames = [ "*.uav-gaming.eu.org" ];
      credentialsFile = "/var/src/secrets/dns01.env";
    };
  };
}

