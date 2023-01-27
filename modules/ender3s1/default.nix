
{ mkModule
, liftToNamespace
, config
, lib
, pkgs
, ... }:
with lib;

mkModule {

  options = cfg: liftToNamespace {

    mcu = mkOption {
      type = types.str;
      default = "stm32f401";
    };

    serialName = mkOption {
      type = types.str;
      default = "ender3s1";
    };

    usbIdVendor = mkOption {
      type = types.str;
      default = "1a86";
    };

    usbIdProduct = mkOption {
      type = types.str;
      default = "7523";
    };

    virtualSdcardPath = mkOption {
      type = types.str;
      default = "/srv/klipper";
    };

  };

  config = cfg: let
    serial = "/dev/${cfg.serialName}";
    mkGcode = splitString "\n";
    iniFormat = pkgs.formats.ini {
      # https://github.com/NixOS/nixpkgs/pull/121613#issuecomment-885241996
      listToValue = l:
        if builtins.length l == 1 then generators.mkValueStringDefault {} (head l)
        else lib.concatMapStrings (s: "\n  ${generators.mkValueStringDefault {} s}") l;
      mkKeyValue = generators.mkKeyValueDefault {} ":";
    };
  in {

    services.udev.packages = singleton (pkgs.writeTextFile {
      name = "${cfg.serialName}-udev-rules";
      destination = "/etc/udev/rules.d/90-${cfg.serialName}-serial.rules";
      text = ''
        SUBSYSTEM=="tty", ATTRS{idVendor}=="${cfg.usbIdVendor}", ATTRS{idProduct}=="${cfg.usbIdProduct}", SYMLINK+="${cfg.serialName}"
      '';
    });

    systemd.tmpfiles.rules = [
      "d ${cfg.virtualSdcardPath} 0770 root klipper - -"
    ];

    services.klipper = {
      enable = true;
      settings = {

        stepper_x = {
          step_pin = "PC2";
          dir_pin = "PB9";
          enable_pin = "!PC3";
          microsteps = "16";
          rotation_distance = "40";
          endstop_pin = "!PA5";
          position_endstop = "-10";
          position_max = "235";
          position_min = "-10";
          homing_speed = "50";
        };
        stepper_y = {
          step_pin = "PB8";
          dir_pin = "PB7";
          enable_pin = "!PC3";
          microsteps = "16";
          rotation_distance = "40";
          endstop_pin = "!PA6";
          position_endstop = "-8";
          position_max = "235";
          position_min = "-13";
          homing_speed = "50";
        };

        stepper_z = {
          step_pin = "PB6";
          dir_pin = "!PB5";
          enable_pin = "!PC3";
          microsteps = "16";
          rotation_distance = "8";
          endstop_pin = "probe:z_virtual_endstop";
          position_max = "270";
          position_min = "-4";
        };

        extruder = {
          step_pin = "PB4";
          dir_pin = "PB3";
          enable_pin = "!PC3";
          microsteps = "16";
          gear_ratio = "42:12";
          rotation_distance = "26.359";
          nozzle_diameter = "0.400";
          filament_diameter = "1.750";
          heater_pin = "PA1";
          sensor_type = "EPCOS 100K B57560G104F";
          sensor_pin = "PC5";
          control = "pid";
          pid_Kp = "23.561";
          pid_Ki = "1.208";
          pid_Kd = "114.859";
          min_temp = "0";
          max_temp = "260 # Set to 300 for S1 Pro";
          pressure_advance = "0.016";
        };

        heater_bed = {
          heater_pin = "PA7";
          sensor_type = "EPCOS 100K B57560G104F";
          sensor_pin = "PC4";
          control = "pid";
          pid_Kp = "71.867";
          pid_Ki = "1.536";
          pid_Kd = "840.843";
          min_temp = "0";
          max_temp = "100 # Set to 110 for S1 Pro";
        };

        "heater_fan hotend_fan" = {
          pin = "PC0";
        };

        fan = {
          pin = "PA0";
        };

        mcu = {
          serial = serial;
          restart_method = "command";
        };

        printer = {
          kinematics = "cartesian";
          max_velocity = "300";
          max_accel = "2000";
          max_z_velocity = "5";
          max_z_accel = "100";
        };

        bltouch = {
          sensor_pin = "^PC14";
          control_pin = "PC13";
          x_offset = "-31.8";
          y_offset = "-40.5";
          z_offset = "1.605";
          probe_with_touch_mode = "true";
          stow_on_each_sample = "false";
        };

        bed_mesh = {
          speed = "120";
          mesh_min = "20, 20";
          mesh_max = "200, 194";
          probe_count = "4,4";
          algorithm = "bicubic";
        };

        safe_z_home = {
          home_xy_position = "147, 154";
          speed = "75";
          z_hop = "10";
          z_hop_speed = "5";
          move_to_previous = "true";
        };

        "filament_switch_sensor e0_sensor" = {
          switch_pin = "!PC15";
          pause_on_runout = "true";
          runout_gcode = "PAUSE";
        };

        pause_resume = {
          recover_velocity = "25";
        };

        bed_screws = {
          screw1 = "20, 29";
          screw2 = "195, 29";
          screw3 = "195, 198";
          screw4 = "20, 198";
        };

        virtual_sdcard = {
          path = cfg.virtualSdcardPath;
        };

        display_status = {};

        "gcode_macro CANCEL_PRINT" = {
          description = "Cancel the actual running print";
          rename_existing = "CANCEL_PRINT_BASE";
          gcode = mkGcode ''
            TURN_OFF_HEATERS
            G91
            G1 Z3
            CANCEL_PRINT_BASE
          '';
        };

        "gcode_macro CENTER" = {
          description = "Center the nozzle";
          gcode = mkGcode ''
            G91
            G1 Z3
            G90
            G1 X110 Y110 F7800
            G1 Z50
          '';
        };

      };
      firmwares.mcu = {
        enable = true;
        serial = null;
        configFile = ./fw/${cfg.mcu};
      };
    };

    systemd.services.moonraker = let
      stateDirectory = "/var/lib/moonraker";
      cfgFile = iniFormat.generate "moonraker.cfg" {
        authorization.trusted_clients = [ "127.0.0.1" ];
        authorization.cors_domains = [ "*" ];

        database.database_path = "${stateDirectory}/database";

        file_manager.config_path = "${stateDirectory}/config";

        machine.provider = "none";

        octoprint_compat = {};

        server = {
          host = "127.0.0.1";
          klippy_uds_address = config.services.klipper.apiSocket;
          port = 7125;
        };
      };
    in {
      description = "Moonraker, an API web server for Klipper";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "klipper.service"];
      wants = [ "klipper.service" ];

      path = [ pkgs.iproute2 ];

      script = ''
        mkdir -p ${stateDirectory}/config
        ${pkgs.moonraker}/bin/moonraker --nologfile -c ${cfgFile}
      '';

      serviceConfig = {
        DynamicUser = true;
        SupplementaryGroups = [ "klipper" ];
        StateDirectory = "moonraker";
        WorkingDirectory = stateDirectory;
        ReadWritePaths = [
          cfg.virtualSdcardPath
        ];
      };
    };

    services.fluidd = {
      enable = true;
    };

    networking.firewall.allowedTCPPorts = [ 80 ];

  };

}
