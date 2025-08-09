{
  mkTrivialModule,
  lib,
  ...
}:
with lib;

mkTrivialModule {

  # Enable Microcode updates
  hardware.cpu.intel.updateMicrocode = mkDefault true;

  # Enable silent fan profile
  services.thinkfan = {
    enable = true;
    sensors = [ ];
    levels = [ ];
    extraArgs = [ "-b-9" ];
    settings = {
      sensors = [
        {
          hwmon = "/sys/class/hwmon";
          name = "coretemp";
          indices = [
            2
            3
          ];
        }
        {
          hwmon = "/sys/class/hwmon";
          name = "acpitz";
          indices = [ 1 ];
        }
      ];
      levels = [
        {
          speed = 0;
          upper_limit = [
            50
            50
            60
          ];
        }
        {
          speed = 2;
          lower_limit = [
            45
            45
            55
          ];
          upper_limit = [
            55
            55
            65
          ];
        }
        {
          speed = 4;
          lower_limit = [
            50
            50
            58
          ];
          upper_limit = [
            60
            60
            68
          ];
        }
        {
          speed = 7;
          lower_limit = [
            55
            55
            60
          ];
          upper_limit = [
            75
            75
            85
          ];
        }
        {
          speed = "level disengaged";
          lower_limit = [
            70
            70
            80
          ];
        }
      ];
    };
  };

}
