{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/profiles/qemu-guest.nix")
    ];

  boot.initrd.availableKernelModules = [ "ahci" "xhci_pci" "virtio_pci" "sym53c8xx" "sr_mod" "virtio_blk" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "system/ephemeral";
      fsType = "zfs";
    };

  fileSystems."/nix" =
    { device = "system/nix";
      fsType = "zfs";
    };

  fileSystems."/persist" =
    { device = "system/data/persist";
      fsType = "zfs";
    };

  fileSystems."/var/lib/minecraft" =
    { device = "system/data/minecraft";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/7105-8C56";
      fsType = "vfat";
    };

  swapDevices = [ ];

  networking.useDHCP = false;

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
