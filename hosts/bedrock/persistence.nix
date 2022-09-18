{ lib, ... }:
{
  boot.initrd.postDeviceCommands = lib.mkAfter ''
    zfs rollback -r system/ephemeral@blank
  '';

  environment.persistence."/persist/fs" = {
    hideMounts = true;
    directories = [
      "/var/lib/tailscale"
      "/etc/ssh"
    ];
    files = [ "/etc/passwd" ];
  };

  system.activationScripts.createPersistFs = {
    text = ''
      mkdir -p /persist/fs
    '';
  };

  system.activationScripts.createPersistentStorageDirs = {
    deps = [ "createPersistFs" ];
  };
}
