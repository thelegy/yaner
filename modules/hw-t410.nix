{ mkTrivialModule
, lib
,...}:
with lib;

mkTrivialModule {

  # Enable Microcode updates
  hardware.cpu.intel.updateMicrocode = mkDefault true;

  # Enable silent fan profile
  services.thinkfan.enable = true;

}
