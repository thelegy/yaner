
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

    serial = mkOption {
      type = types.str;
      default = "/dev/ender3s1";
    };

    companionMcu = mkOption {
      type = types.str;
      default = "rp2040";
    };

    companionSerial = mkOption {
      type = types.nullOr types.str;
      default = null;
    };

    virtualSdcardPath = mkOption {
      type = types.str;
      default = "/srv/klipper";
    };

  };

  config = cfg: let
    mkGcode = splitString "\n";
    iniFormat = pkgs.formats.ini {
      # https://github.com/NixOS/nixpkgs/pull/121613#issuecomment-885241996
      listToValue = l:
        if builtins.length l == 1 then generators.mkValueStringDefault {} (head l)
        else lib.concatMapStrings (s: "\n  ${generators.mkValueStringDefault {} s}") l;
      mkKeyValue = generators.mkKeyValueDefault {} ":";
    };
    hasCompanion = !isNull cfg.companionSerial;
  in {

    systemd.tmpfiles.rules = [
      "d ${cfg.virtualSdcardPath} 0770 root klipper - -"
    ];

    services.klipper = {
      enable = true;
      settings = mkMerge [
        {

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
            serial = cfg.serial;
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
            screw1_name = "front left";
            screw2 = "195, 29";
            screw2_name = "front right";
            screw3 = "195, 198";
            screw3_name = "back right";
            screw4 = "20, 198";
            screw4_name = "back left";
          };

          screws_tilt_adjust = {
            screw1 = "54, 67";
            screw1_name = "front left";
            screw2 = "227, 67";
            screw2_name = "front right";
            screw3 = "227, 235";
            screw3_name = "back right";
            screw4 = "54, 235";
            screw4_name = "back left";
          };

          virtual_sdcard = {
            path = cfg.virtualSdcardPath;
          };

          display_status = {};

          exclude_object = {};

          idle_timeout = {
            timeout = 1800;
            gcode = mkGcode ''
              TURN_OFF_HEATERS
              M84
            '';
          };

          "gcode_macro INIT" = {
            gcode = mkGcode ''
              G28
              BED_MESH_CALIBRATE
              CENTER
            '';
          };

          "gcode_macro START_PRINT" = {
            gcode = mkGcode ''
              {% set BED_TEMP = params.BED_TEMP|default(60)|float %}
              {% set EXTRUDER_TEMP = params.EXTRUDER_TEMP|default(190)|float %}
              # Reset interfering state
              CLEAR_PAUSE
              M117
              # Start bed heating
              M140 S{BED_TEMP}
              # Set indermediate nozzle temperature
              M104 S150
              # Use absolute coordinates
              G90
              # Home the printer X and Y
              G28 X Y
              # Wait for bed to reach temperature
              M190 S{BED_TEMP}
              # Home the printer
              G28 Z
              # Set nozzle temperature
              M104 S{EXTRUDER_TEMP}
              # Move to idle position for pre-ooze
              G1 X235 Y0 Z30 F3000
              # Wait for the nozzle to heat up
              M109 S{EXTRUDER_TEMP}
              # Ooze some material
              G1 E40 F200
              # Move to prime position
              G1 X2.0 Y10 Z0.28 F3000
              # Prime the nozzle with a double line
              G92 E0
              G1 X2.0 Y140 E10 F1500
              G1 X2.3 Y140 F5000
              G92 E0
              G1 X2.3 Y10 E10 F1200
              G92 E0
            '';
          };

          "gcode_macro END_PRINT" = {
            gcode = mkGcode ''
              {% set max_z = printer.toolhead.axis_maximum.z %}
              {% set x_park = printer.toolhead.axis_maximum.x %}
              {% set y_park = printer.toolhead.axis_maximum.y %}
              # Turn off bed, extruder, and fan
              M140 S0
              M104 S0
              M106 S0
              # Set to absolute
              G90
              # Move nozzle away from print a bit
              G1 Z{[max_z, 3+printer.toolhead.position.z] | min} E-3 F300
              # Present the finished print
              G1 X{x_park} Y{y_park} F6000
              G1 Z{[max_z, 100+printer.toolhead.position.z] | min} F300
              # Disable steppers
              M84 X Y E
            '';
          };

          "gcode_macro PAUSE" = {
            description = "Pause the actual running print";
            rename_existing = "PAUSE_BASE";
            variable_extrude = 1.0;
            variable_extruder_temp = 150;
            gcode = mkGcode ''
              {% set E = printer["gcode_macro PAUSE"].extrude|float %}
              {% set max_z = printer.toolhead.axis_maximum.z|float %}

              PAUSE_BASE
              G90

              EXTRUDE_IF_POSSIBLE E=-{E}

              SET_GCODE_VARIABLE MACRO=PAUSE VARIABLE=extruder_temp VALUE={printer.extruder.target}
              M104 S{[150, printer.extruder.temperature, printer.extruder.target] | min}

              {% if "xyz" in printer.toolhead.homed_axes %}
                G1 Z{[max_z, 10+printer.toolhead.position.z] | min} F300
                G1 X{printer.toolhead.axis_maximum.x} Y{printer.toolhead.axis_maximum.y} F6000
              {% else %}
                {action_respond_info("Printer not homed")}
              {% endif %}
            '';
          };

          "gcode_macro RESUME" = {
            description = "Resume the actual running print";
            rename_existing = "RESUME_BASE";
            gcode = mkGcode ''
              {% set E = printer["gcode_macro PAUSE"].extrude|float %}
              {% set max_z = printer.toolhead.axis_maximum.z|float %}

              {% if 'VELOCITY' in params|upper %}
                {% set get_params = ('VELOCITY=' + params.VELOCITY)  %}
              {%else %}
                {% set get_params = "" %}
              {% endif %}

              M117
              G90

              {% if "xyz" in printer.toolhead.homed_axes %}
                G1 Z{[max_z, 3+printer.toolhead.position.z] | min} F300
                G1 X{printer.toolhead.axis_maximum.x} Y0 F6000
              {% else %}
                {action_respond_info("Printer not homed")}
              {% endif %}

              M109 S{printer["gcode_macro PAUSE"].extruder_temp}
              EXTRUDE_IF_POSSIBLE E={E}
              RESUME_BASE {get_params}
            '';
          };

          "gcode_macro EXTRUDE_IF_POSSIBLE" = {
            gcode = mkGcode ''
              {% set E = params.E|float %}
              {% set F = params.F|default(2100)|float %}

              {% if printer.extruder.can_extrude|lower == 'true' %}
                M83
                G1 E{E} F{F}
              {% else %}
                {action_respond_info("Extruder not hot enough")}
              {% endif %}
            '';
          };

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

        }
        (optionalAttrs hasCompanion {
          "mcu companion" = {
            serial = cfg.companionSerial;
          };
        })
      ];
      firmwares.mcu = {
        enable = true;
        serial = null;
        configFile = ./fw/${cfg.mcu};
      };
      firmwares."mcu companion" = mkIf hasCompanion {
        enable = true;
        serial = null;
        configFile = ./fw/${cfg.companionMcu};
      };
    };

    systemd.services.moonraker = let
      cfgFile = iniFormat.generate "moonraker.cfg" {
        authorization.trusted_clients = [ "127.0.0.1" ];
        authorization.cors_domains = [ "*" ];

        machine = {
          provider = "none";
          validate_service = false;
        };

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
        ln -snf ${cfg.virtualSdcardPath} $STATE_DIRECTORY/gcodes
        rm $STATE_DIRECTORY/gcodes/klipper
        ${pkgs.moonraker}/bin/moonraker --nologfile -d $STATE_DIRECTORY -c ${cfgFile}
      '';

      serviceConfig = {
        DynamicUser = true;
        SupplementaryGroups = [ "klipper" ];
        StateDirectory = "moonraker";
        ReadWritePaths = [
          cfg.virtualSdcardPath
        ];
      };
    };

    services.fluidd = {
      enable = true;
      nginx.extraConfig = ''
        client_max_body_size 50M;
      '';
    };

    networking.firewall.allowedTCPPorts = [ 80 ];

  };

}
