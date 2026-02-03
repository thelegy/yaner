{
  config,
  lib,
  liftToNamespace,
  mkModule,
  ...
}:
mkModule {

  options =
    cfg:
    liftToNamespace {

      dataDir = lib.mkOption {
        type = lib.types.str;
      };

      exportDir = lib.mkOption {
        type = lib.types.str;
      };

      consumptionDir = lib.mkOption {
        type = lib.types.str;
        default = "/var/lib/paperless-consume";
      };

      sopsCredentialsFile = lib.mkOption {
        type = lib.types.str;
        default = "paperless-env";
      };

      domain = lib.mkOption {
        type = lib.types.str;
        default = "paperless.beinke.cloud";
      };

    };

  config =
    cfg:
    let
      ip = "127.0.0.1";
      port = config.services.paperless.port;
    in
    {

      sops.secrets.${cfg.sopsCredentialsFile} = {
        format = "yaml";
        mode = "0600";
        restartUnits = [
          "paperless-consumer.service"
          "paperless-scheduler.service"
          "paperless-task-queue.service"
          "paperless-web.service"
        ];
      };

      services.paperless = {
        enable = true;
        address = ip;
        inherit (cfg) dataDir consumptionDir;
        environmentFile = config.sops.secrets.${cfg.sopsCredentialsFile}.path;
        configureTika = true;
        settings = {
          PAPERLESS_CONSUMER_IGNORE_PATTERN = [
            ".DS_STORE/*"
            "desktop.ini"
          ];
          PAPERLESS_OCR_LANGUAGE = "deu+eng";
          PAPERLESS_OCR_USER_ARGS = {
            optimize = 1;
            pdfa_image_compression = "lossless";
          };
          PAPERLESS_CONSUMER_ENABLE_ASN_BARCODE = 1;
          PAPERLESS_CONSUMER_BARCODE_UPSCALE = 5;
          PAPERLESS_CONSUMER_BARCODE_DPI = 300;
          PAPERLESS_MAX_IMAGE_PIXELS = 89478485 * 4;
          PAPERLESS_URL = "https://paperless.beinke.cloud";
          PAPERLESS_TRUSTED_PROXIES = "127.0.0.1";
        };
        exporter = {
          enable = true;
          directory = cfg.exportDir;
          onCalendar = null;
        };
      };

      systemd.services.paperless-exporter = {
        partOf = [ "pre-backup.target" ];
        requiredBy = [ "pre-backup.target" ];
        serviceConfig.Type = "oneshot";
      };

      users.groups.paperless-consume = {};
      users.users.paperless.extraGroups = [ "paperless-consume" ];

      systemd.tmpfiles.rules = lib.mkAfter [
        "z '${config.services.paperless.consumptionDir}' 0770 - paperless-consume - -"
        "z '${config.services.paperless.exporter.directory}' 0750 - - - -"
      ];

      wat.thelegy.backup.extraExcludes = [
        cfg.dataDir
      ];

      wat.thelegy.traefik.dynamicConfigs.paperless = {
        http.services.paperless.loadBalancer = {
          servers = [ { url = "http://${ip}:${toString port}"; } ];
        };
        http.routers.paperless = {
          rule = "Host(`${cfg.domain}`)";
          service = "paperless";
        };
      };

    };

}
