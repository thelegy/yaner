{ wat, ... }:
{
  flake.nixosModules.kea = (
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let

      cfg = config.services.kea;

      writeConfig =
        cfg:
        let
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
          wants = [ "network-online.target" ];
          after = [ "network-online.target" ];
          preStart = ''
            [[ -d /var/kea && ! -d /var/lib/kea ]] && mv /var/kea /var/lib/kea
            mkdir -m 700 -p /var/run/kea /var/lib/kea
          '';
          serviceConfig =
            let
              configFile = writeConfig cfg;
              args = [
                "@${cfg.package}/bin/kea-dhcp4"
                "kea-dhcp4"
                "-c"
                "${configFile}"
              ];
            in
            {
              ExecStart = lib.concatMapStringsSep " " lib.escapeShellArg args;
            };
        };
      };

    in
    {

      options.services.kea = {
        enable = lib.mkEnableOption "Kea service";
        package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.kea;
          defaultText = "pkgs.kea";
          description = ''
            The package used for the Kea service.
          '';
        };
        interfaces = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          defaultText = "[]";
          description = ''
            The interfaces Kea should listen on.
          '';
        };
        additionalConfig = lib.mkOption {
          type = lib.types.attrs;
          default = { };
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

  );
}
