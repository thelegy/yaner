{ mkModule
, config
, lib
, liftToNamespace
, ... }:
with lib;

let
  toplevel_cfg = config;
in mkModule {
  options = cfg: liftToNamespace {

    useACMEHost = mkOption {
      type = types.str;
      default = config.networking.fqdn;
    };

    mailDomain = mkOption {
      type = types.str;
      default = "beinke.cloud";
    };

    imapServer = mkOption {
      type = types.str;
      default = "imap.beinke.cloud";
    };

    smtpServer = mkOption {
      type = types.str;
      default = "smtp.beinke.cloud";
    };

    autoconfigDomains = mkOption {
      type = types.listOf types.str;
      default = [ cfg.mailDomain ];
      # See https://wiki.mozilla.org/Thunderbird:Autoconfiguration
    };

    defaultQuota = mkOption {
      type = types.str;
      default = "5G";
    };

  } // {

    mailserver.loginAccounts = mkOption {
      type = types.attrsOf (types.submodule ({ config, ... }: {
        options = {

          useSopsHashedPassword = mkOption {
            type = types.nullOr types.str;
            default = "mailserver/loginAccounts/${config.name}/hashedPassword";
          };

        };
        config = {

          hashedPasswordFile =
            mkIf
              (!isNull config.useSopsHashedPassword)
              toplevel_cfg.sops.secrets.${config.useSopsHashedPassword}.path;

          quota = mkDefault cfg.defaultQuota;

        };
      }));
    };

  };
  config = cfg: let
    acmePath = "/var/lib/acme/${cfg.useACMEHost}";
    autoconfigXml = ''
      <?xml version="1.0" encoding="UTF-8"?>

      <clientConfig version="1.1">
        <emailProvider id="${cfg.mailDomain}">
          <domain>${cfg.mailDomain}</domain>
          <displayName>%EMAILADDRESS%</displayName>
          <displayShortName>%EMAILLOCALPART%</displayShortName>
          <incomingServer type="imap">
            <hostname>${cfg.imapServer}</hostname>
            <port>993</port>
            <socketType>SSL</socketType>
            <authentication>password-cleartext</authentication>
            <username>%EMAILADDRESS%</username>
          </incomingServer>
          <outgoingServer type="smtp">
            <hostname>${cfg.smtpServer}</hostname>
            <port>465</port>
            <socketType>SSL</socketType>
            <authentication>password-cleartext</authentication>
            <username>%EMAILADDRESS%</username>
          </outgoingServer>
        </emailProvider>
      </clientConfig>
    '';
  in {

    wat.thelegy.acme.reloadUnits = [
      "dovecot2.service"
      "postfix.service"
    ];

    sops.secrets = pipe toplevel_cfg.mailserver.loginAccounts [
      attrValues
      (map (x: x.useSopsHashedPassword))
      (filter isString)
      (flip genAttrs (sopsKey: {}))
    ];

    services.nginx.virtualHosts.autoconfig = {
      useACMEHost = config.networking.fqdn;
      forceSSL = true;
      serverAliases = map (x: "autoconfig.${x}") cfg.autoconfigDomains;
      locations."/".return = "404";
      locations."/mail/config-v1.1.xml".extraConfig = ''
        default_type application/xml;
        charset utf8;
        return 200 '${replaceStrings ["\n"] ["\\n"] autoconfigXml}';
      '';
    };

    # Use optionalattrs because mkIf pushes the test down into undefined options
    mailserver = {
      enable = true;

      # Disable starttls (the ssl endpoint defaults to enabled as well)
      enableImap = false;

      # Disable starttls (the ssl endpoint defaults to enabled as well)
      enableSubmission = false;

      # Give the users a tool to manage their sive scripts
      enableManageSieve = true;

      fqdn = config.networking.fqdn;

      # As per the dovecot documentation the following is sane and ensures
      # the greatest level of compability with different clients.
      hierarchySeparator = "/";
      useFsLayout = true;

      # How expensive is "_very_ expensive"?
      virusScanning = false;

      # Manual certificate setup
      certificateScheme = "manual";
      keyFile = "${acmePath}/key.pem";
      certificateFile = "${acmePath}/cert.pem";
    };

    systemd.services.dovecot2.serviceConfig = {
      SupplementaryGroups = [ "acme" ];
    };
    systemd.services.postfix.serviceConfig = {
      SupplementaryGroups = [ "acme" ];
    };

    # TODO: snappymail
    # TODO: dmarc-metrics-exporter
    # TODO: aid with dns config, e.g. generated zonefile, ect.

  };
}
