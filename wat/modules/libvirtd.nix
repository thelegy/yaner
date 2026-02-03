{
  mkTrivialModule,
  lib,
  pkgs,
  ...
}:
with lib;

mkTrivialModule {

  security.polkit.enable = true;

  virtualisation.libvirtd = {
    enable = true;
    qemu.runAsRoot = false;
    onShutdown = mkDefault "shutdown";
  };

}
