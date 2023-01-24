{ mkTrivialModule
, lib
, pkgs
, ... }:
with lib;

mkTrivialModule {

  security.polkit.enable = true;

  virtualisation.libvirtd = {
    enable = true;
    qemu.package = mkDefault pkgs.qemu_kvm;
    qemu.runAsRoot = false;
    onShutdown = mkDefault "shutdown";
  };

}
