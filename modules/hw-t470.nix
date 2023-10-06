{ mkTrivialModule
, lib
, pkgs
, ... }:
with lib;

mkTrivialModule {
  # Enable Microcode updates
  hardware.cpu.intel.updateMicrocode = mkDefault true;

  # Undervolting the cpu for less energy consumation and more power
  services.undervolt = {
    enable = true;
    coreOffset = -80;  # undervolt the CPU in mV
  };

  hardware.opengl = {
    enable = true;
    extraPackages = [ pkgs.intel-media-driver ];
  };

  # Disable extremely spammy acpi interrupt (probably usb-c related)
  # https://askubuntu.com/questions/1275749/acpi-event-69-made-my-system-unusable
  boot.kernelParams = [ "acpi_mask_gpe=0x69" ];

  # Enable brightness switches
  services.illum.enable = true;
}
