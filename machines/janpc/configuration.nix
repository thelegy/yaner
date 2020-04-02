{ pkgs, ... }:

{
  imports = [
    ../../layers/workstation
    ../../layers/irb-kerberos
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.luks.devices.system = {
    device = "/dev/disk/by-uuid/1026ba1d-40ca-4f4b-9cff-fcc897cd1b09";
    allowDiscards = true;
  };

  fileSystems."/mnt/data" = {
    device = "/dev/disk/by-label/data";
    fsType = "btrfs";
    options = [
      "compress=zstd"
    ];
  };

  users.users.beinke.packages = [
    pkgs.patchelf
  ];

}
