{ pkgs, ... }:

{
  imports = [
    ../../layers/workstation
    ../../layers/irb-kerberos
  ];

  userconfig.thelegy.builder.enable = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.luks.devices.system = {
    device = "/dev/disk/by-uuid/924d6200-141f-4e95-9adc-fe410687be5b";
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
    pkgs.multimc
  ];

}
