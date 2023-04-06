{ mkModule
, config
, lib
, liftToNamespace
, ... }:
with lib;

mkModule {
  options = cfg: liftToNamespace {

    sopsPasswordFile = mkOption {
      type = types.str;
      default = "syncthing-gui-password";
    };

    passwordFile = mkOption {
      type = types.nullOr types.str;
      default = null;
    };

  };
  config = cfg: let
    inherit (config.services.syncthing) user group configDir dataDir package;
    usesSops = cfg.passwordFile == null;
    passwordFile =
      if usesSops
      then config.sops.secrets.${cfg.sopsPasswordFile}.path
      else cfg.passwordFile;
  in {

    sops.secrets.${cfg.sopsPasswordFile} = mkIf usesSops {
      format = "yaml";
      mode = "0600";
      restartUnits = [ "syncthing.service" ];
    };

    systemd.tmpfiles.rules = [ "d ${dataDir} 0700 ${user} ${group}" ];

    services.syncthing = {
      enable = true;
      openDefaultPorts = true;

      user = mkDefault "beinke";
      group = mkDefault "users";
      dataDir = mkDefault "/srv/sync";

      overrideDevices = false;
      overrideFolders = false;
      extraOptions = {
        options = {
          urAccepted = -1;
          crashReportingEnabled = false;
        };
        defaults = {
          folder = {
            path = dataDir;
          };
        };
      };
    };

    systemd.services.syncthing = {
      confinement = {
        enable = true;
      };
      preStart = ''
        ${package}/bin/syncthing generate \
          --home=${configDir} \
          --gui-user=${user} \
          --gui-password=- \
          --skip-port-probing \
          --no-default-folder \
          < $CREDENTIALS_DIRECTORY/gui-password
      '';
      serviceConfig = {
        BindPaths = [ dataDir ];
        BindReadOnlyPaths = [
          "/etc/resolv.conf"
          "/etc/ssl/certs/ca-certificates.crt"
          "/etc/static/ssl/certs/ca-certificates.crt"
        ];
        LoadCredential = "gui-password:${passwordFile}";
      };
    };

    environment.systemPackages = [ package ];

  };
}
