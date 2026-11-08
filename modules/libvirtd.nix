{ wat, ... }:
{
  flake.nixosModules.libvirtd = wat.mkModule [ "libvirtd" ] (
    {
      cfg,
      lib,
      pkgs,
      ...
    }:

    {

      security.polkit.enable = true;

      virtualisation.libvirtd = {
        enable = true;
        qemu.runAsRoot = false;
        onShutdown = lib.mkDefault "shutdown";
      };

    }

  );
}
