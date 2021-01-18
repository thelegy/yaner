{ config, lib, pkgs, ... }:

with lib;


let

  cfg = config.services.kea;

  writeConfig = cfg: let
    localConfiguration = {
      Dhcp4 = {
        "interfaces-config" = {
          interfaces = cfg.interfaces;
        };
      };
    };
    configuration = lib.recursiveUpdate localConfiguration cfg.additionalConfig;
  in
    pkgs.writeText "kea.json" (builtins.toJSON configuration);

  keaService = {
    "kea" = {
      description = "Kea DHCP server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      preStart = ''
        [[ -d /var/kea && ! -d /var/lib/kea ]] && mv /var/kea /var/lib/kea
        mkdir -m 700 -p /var/run/kea /var/lib/kea
      '';
      serviceConfig =
      let
        configFile = writeConfig cfg;
        args = [
          "@${cfg.package}/bin/kea-dhcp4" "kea-dhcp4"
          "-c" "${configFile}"
        ];
      in {
        ExecStart = concatMapStringsSep " " escapeShellArg args;
      };
    };
  };


in {

  options.services.kea = {
    enable = mkEnableOption "Kea service";
    package = mkOption {
      type = types.package;
      default = pkgs.kea;
      defaultText = "pkgs.kea";
      description = ''
        The package used for the Kea service.
      '';
    };
    interfaces = mkOption {
      type = types.listOf types.str;
      default = [];
      defaultText = "[]";
      description = ''
        The interfaces Kea should listen on.
      '';
    };
    additionalConfig = mkOption {
      type = types.attrs;
      default = {};
      defaultText = "{}";
      description = ''
        Additional configuration for Kea
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services = keaService;
  };

}
