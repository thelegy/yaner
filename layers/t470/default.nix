{ lib, ... }:
with lib;
{
  # Enable Microcode updates
  hardware.cpu.intel.updateMicrocode = mkDefault true;

  # Undervolting the cpu for less energy consumation and more power
  services.undervolt = {
    enable = true;
    coreOffset = -80;  # undervolt the CPU in mV
  };
}
