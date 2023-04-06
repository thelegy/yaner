{ mkMachine, ... }:

mkMachine {} ({ lib, pkgs, ... }:
with lib;

let
  interface = "enp6s0";
in
{
  imports = [
    ./hardware-configuration.nix
  ];

  wat.installer.btrfs = {
    enable = true;
    installDisk = "/dev/disk/by-id/nvme-Samsung_SSD_980_PRO_2TB_S69ENF0R215215M";
    swapSize = "8GiB";
    luks.enable = true;
  };

  wat.thelegy.workstation.enable = true;
  wat.thelegy.builder.enable = true;
  wat.thelegy.prebuild.enable = true;
  wat.thelegy.syncthing.enable = true;

  networking.useDHCP = false;
  networking.interfaces.${interface}.useDHCP = true;

  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelParams = [ "acpi_enforce_resources=lax" ];
  boot.kernelModules = [ "nct6775" ];

  boot.initrd.availableKernelModules = [ "igc" ];
  wat.thelegy.ssh-unlock = {
    enable = true;
    inherit interface;
  };

  wat.thelegy.bs-oneclick.enable = true;

  wat.thelegy.libvirtd.enable = true;

  hardware.cpu.amd.updateMicrocode = true;
  powerManagement.cpuFreqGovernor = "schedutil";

  hardware.opengl.extraPackages = with pkgs; [
    #rocm-opencl-icd
    #rocm-opencl-runtime
    amdvlk
  ];

  # To enable Vulkan support for 32-bit applications, also add:
  hardware.opengl.extraPackages32 = with pkgs.driversi686Linux; [
    amdvlk
  ];
  environment.variables.AMD_VULKAN_ICD = "RADV";  # as opposed to AMDVLK

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

  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  users.users.beinke.packages = with pkgs; [
    blender
    patchelf
    prismlauncher
  ];

  system.stateVersion = "22.05";

})
