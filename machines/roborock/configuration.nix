{ config, options, pkgs, channels, ... }:
let

  linux_rock64_4_19 = pkgs.callPackage ./linux-rock64/4.19.nix {
    kernelPatches = [ pkgs.kernelPatches.bridge_stp_helper ];
  };
  linux_rock64_4_20 = pkgs.callPackage ./linux-rock64/4.20.nix {
    kernelPatches = [ pkgs.kernelPatches.bridge_stp_helper ];
  };
  linux_rock64_5_3 = pkgs.callPackage ./linux-rock64/5.3.nix {
    kernelPatches = [ pkgs.kernelPatches.bridge_stp_helper ];
  };

  linuxPackages_rock64_4_19 = pkgs.recurseIntoAttrs (pkgs.linuxPackagesFor linux_rock64_4_19);
  linuxPackages_rock64_4_20 = pkgs.recurseIntoAttrs (pkgs.linuxPackagesFor linux_rock64_4_20);
  linuxPackages_rock64_5_3 = pkgs.recurseIntoAttrs (pkgs.linuxPackagesFor linux_rock64_5_3);

in {

  imports = [
    ./hardware-configuration.nix
    ../../layers/box
  ];

  # Use the extlinux boot loader. (NixOS wants to enable GRUB by default)
  boot.loader.grub.enable = false;
  # Enables the generation of /boot/extlinux/extlinux.conf
  boot.loader.generic-extlinux-compatible.enable = true;

  boot.kernelPackages = linuxPackages_rock64_5_3;

  users.users.nix = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMCC4cFL1xcZOsIzXg1b/M4b89ofMKErNhg9s+0NdBVC beinke@th1"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPMkJA05G5ozn/pYRxrbQbk8lRynG4jH5LG1fua0Jo7c root@th1"
    ];
  };

  nix.trustedUsers = [ "beinke" "nix" ];

  system.stateVersion = "19.03";

}
