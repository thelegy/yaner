{ config, lib, pkgs, modulesPath, ... }:

let

  cryt_uuid = "43c5d78f-7ac8-4bab-8d65-d49ce802a8b5";
  boot_uuid = "02C9-F1A8";
  root_uuid = "418207c3-4a35-4dab-97f1-465aecb3829a";
  swap_uuid = "4690e529-fb66-41d8-bfc3-42f604259e4b";

  root_subvolume = subvolid:
  {
    device = "/dev/disk/by-uuid/${root_uuid}";
    fsType = "btrfs";
    options = [
      "compress=zstd"
      "subvolid=${toString subvolid}"
    ];
  };

in {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ "dm-snapshot" ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.luks.devices.th1 = {
    device = "/dev/disk/by-uuid/${cryt_uuid}";
    allowDiscards = true;
  };

  fileSystems."/" = root_subvolume 256;
  fileSystems."/nix" = root_subvolume 258;
  fileSystems."/home" = root_subvolume 357;

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/${boot_uuid}";
    fsType = "vfat";
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/${swap_uuid}"; }
  ];

  nix.settings.max-jobs = lib.mkDefault 4;
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
}
