{ mkTrivialModule
, lib
,...}:
with lib;

mkTrivialModule {

  # Enable Microcode updates
  hardware.cpu.intel.updateMicrocode = mkDefault true;

  # Enable brightness switches
  services.illum.enable = true;

  # Enable silent fan profile
  services.thinkfan.enable = true;

}
