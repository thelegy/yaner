{ lib, pkgs, ... }:
with lib;

{
  imports = [
    ../../layers/workstation
    ../../layers/irb-kerberos
  ];

  userconfig.thelegy.builder.enable = true;

  networking.useDHCP = false;
  networking.interfaces.enp7s0.useDHCP = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelParams = [ "acpi_enforce_resources=lax" ];
  boot.kernelModules = [ "nct6775" ];

  boot.initrd.luks.devices.system = {
    device = "/dev/disk/by-uuid/924d6200-141f-4e95-9adc-fe410687be5b";
    allowDiscards = true;
  };

  boot.initrd.availableKernelModules = [ "igc" ];
  boot.initrd.preLVMCommands = mkOrder 300 "ip link set enp7s0 up; sleep 5";
  #boot.initrd.preLVMCommands = "/bin/ash";
  boot.initrd.network.enable = true;
  boot.initrd.network.ssh = {
    enable = true;
    hostKeys = [ "/etc/secrets/initrd_ed25519_host_key" ];
  };

  hardware.cpu.amd.updateMicrocode = true;
  powerManagement.cpuFreqGovernor = "schedutil";

  hardware.opengl.extraPackages = with pkgs; [
    #rocm-opencl-icd
    #rocm-opencl-runtime
    amdvlk
  ];

  fileSystems."/mnt/data" = {
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

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  users.users.beinke.extraGroups = [ "vboxusers" "dialout" ];

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
    gtkUsePortal = true;
  };

  services.pipewire = {
    enable = true;
    pulse.enable = false;
  };

  users.users.beinke.packages = with pkgs; [
    blender
    patchelf
    multimc
  ];

}
