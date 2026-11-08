{ wat, ... }:
{
  flake.nixosModules.libvirtd = wat.mkModule [ "libvirtd" ] (
    {
      cfg,
      lib,
      pkgs,
      ...
    }:
    with lib;

    {

      security.polkit.enable = true;

      virtualisation.libvirtd = {
        enable = true;
        qemu.runAsRoot = false;
        onShutdown = mkDefault "shutdown";
      };

    }

  );
}
