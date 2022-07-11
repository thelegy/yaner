{ mkMachine, ... }:

mkMachine {} ({ lib, pkgs, ... }:
with lib;

{
  imports = [
    ./hardware-configuration.nix
    ../../layers/workstation
    ../../layers/irb-kerberos
  ];

  wat.installer.btrfs = {
    enable = true;
    installDisk = "/dev/disk/by-id/nvme-Samsung_SSD_980_PRO_2TB_S69ENF0R215215M";
    swapSize = "8GiB";
    luks.enable = true;
  };

  wat.thelegy.builder.enable = true;

  networking.useDHCP = false;
  networking.interfaces.enp7s0.useDHCP = true;

  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelParams = [ "acpi_enforce_resources=lax" ];
  boot.kernelModules = [ "nct6775" ];

  boot.initrd.availableKernelModules = [ "igc" ];
  wat.thelegy.ssh-unlock = {
    enable = true;
    interface = "enp7s0";
  };

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = mkDefault pkgs.qemu_kvm;
      runAsRoot = false;
    };
    onShutdown = "shutdown";
  };

  hardware.cpu.amd.updateMicrocode = true;
  powerManagement.cpuFreqGovernor = "schedutil";

  hardware.opengl.extraPackages = with pkgs; [
    #rocm-opencl-icd
    #rocm-opencl-runtime
    amdvlk
  ];

  fileSystems."/data" = {
    device = "/dev/disk/by-label/data";
    fsType = "btrfs";
    options = [
      "compress=zstd"
      "x-systemd.automount"
      "noauto"
    ];
  };


  networking.firewall.allowedTCPPorts = [
    8080
  ];

  boot.binfmt.emulatedSystems = [ "aarch64-linux" "armv7l-linux" ];

  users.groups.libvirt = {};
  users.users.beinke.extraGroups = [ "vboxusers" "dialout" "libvirt" ];

  programs.sway.extraSessionCommands = ''
    export GTK_THEME=Blackbird
    export GTK_ICON_THEME=Tango
    export MOZ_ENABLE_WAYLAND=1
    export MOZ_USE_XINPUT2=1
    export XDG_SESSION_TYPE=wayland
    export XDG_CURRENT_DESKTOP=sway
  '';

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [ xdg-desktop-portal-wlr ];
  };
  environment.sessionVariables.GTK_USE_PORTAL = "1";

  services.pipewire = {
    enable = true;
    pulse.enable = false;
  };

  users.users.beinke.packages = with pkgs; [
    blender
    patchelf
    polymc
  ];

  system.stateVersion = "22.05";
})
