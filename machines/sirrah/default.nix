{ mkMachine, ... }:

mkMachine {} ({ lib, pkgs, config, ... }:
with lib;

let
  interface = "enp6s0";
in
{

  system.stateVersion = "22.05";

  imports = [
    ./hardware-configuration.nix
    ./pipewire.nix
  ];

  wat.installer.btrfs = {
    enable = true;
    installDisk = "/dev/disk/by-id/nvme-Samsung_SSD_980_PRO_2TB_S69ENF0R215215M";
    swapSize = "8GiB";
    luks.enable = true;
  };

  wat.thelegy.builder.enable = true;
  wat.thelegy.prebuild.enable = true;
  wat.thelegy.syncthing.enable = true;
  wat.thelegy.workstation.enable = true;

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

  # Enable systemd-networkd in addition to NetworkManager
  systemd.network.enable = true;
  systemd.network.wait-online.enable = false;


  wat.thelegy.libvirtd.enable = true;

  hardware.cpu.amd.updateMicrocode = true;
  powerManagement.cpuFreqGovernor = "schedutil";

  hardware.graphics.extraPackages = with pkgs; [
    #rocm-opencl-icd
    #rocm-opencl-runtime
    amdvlk
  ];

  # To enable Vulkan support for 32-bit applications, also add:
  hardware.graphics.extraPackages32 = with pkgs.driversi686Linux; [
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

  users.users.beinke.packages = with pkgs; [
    #BeatSaberModManager
    blender
    patchelf
  ];

})
