{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.he-dns;
  cfgs = attrValues cfg;

  perDomainConfig = {name, ...}: {
    options = {
      domain = mkOption {
        type = types.str;
        default = "";
        description = ''
          The Domain to configure HE DDNS for.
        '';
      };
      keyfile = mkOption {
        type = types.str;
        description = ''
          Path to a file containing the HE DDNS password.
        '';
      };
      updateA = mkOption {
        type = types.bool;
        default = true;
        description = ''
          If to update the A record.
        '';
      };
      updateAAAA = mkOption {
        type = types.bool;
        default = true;
        description = ''
          If to update the AAAA record.
        '';
      };
      onCalendar = mkOption {
        type = with types; nullOr str;
        default = "*:00/10:00";
        example = "*:00/5:00";
        description = ''
          OnCalendar value for the systemd-timer. See SYSTEMD.TIME(7).
        '';
      };
      onBoot = mkOption {
        type = with types; nullOr str;
        default = "1min";
        example = "5min";
        description = ''
          OnBoot value for the systemd-timer. See SYSTEMD.TIME(7).
        '';
      };
      updateEndpoint = mkOption {
        type = types.str;
        default = "https://dyn.dns.he.net/nic/update";
        description = ''
          Update Url. Changes to this are very unlikely.
        '';
      };
    };
    config = {
      domain = mkDefault name;
    };
  };

  flattenList = l: builtins.foldl' (x: y: x//y) {} l;

  ddnsCurlLine = domainCfg: flags: ''
    ${pkgs.curl}/bin/curl --silent ${flags} "${domainCfg.updateEndpoint}" -d "hostname=${domainCfg.domain}" -d "password=$password"
    echo
  '';

  ddnsScript = domainCfg: ''
    password="$(cat ${domainCfg.keyfile})"
  '' + (optionalString domainCfg.updateAAAA (ddnsCurlLine domainCfg "-6"))
     + (optionalString domainCfg.updateA (ddnsCurlLine domainCfg "-4"));

  ddnsService = domainCfg: mkIf (domainCfg.updateAAAA || domainCfg.updateA) {
    "he-ddns-${domainCfg.domain}" = {
      description = "Hurricane Electric DDNS Update Service";
      requires = [ "network-online.target" ];
      after = [ "network-online.target" ];
      script = ddnsScript domainCfg;
    };
  };

  ddnsTimer = domainCfg: mkIf (domainCfg.updateAAAA || domainCfg.updateA) {
    "he-ddns-${domainCfg.domain}" = {
      description = "Hurricane Electric DDNS Update Timer";
      wantedBy = [ "multi-user.target" ];
      requires = [ "network-online.target" ];
      after = [ "network-online.target" ];
      timerConfig = { Unit = "he-ddns-${domainCfg.domain}.service"; }
        // (optionalAttrs (!isNull domainCfg.onBoot) { OnBoot = domainCfg.onBoot; })
        // (optionalAttrs (!isNull domainCfg.onCalendar) { OnCalendar = domainCfg.onCalendar; });
    };
  };

in {

  options.services.he-dns = mkOption {
    type = with types; loaOf (submodule perDomainConfig);
    default = {};
    description = ''
     Timer for updating HE DDNS Records.
     Documentation: https://dns.he.net/docs.html
     '';
  };

  config = {
    systemd.services = flattenList (map ddnsService cfgs);
    systemd.timers = flattenList (map ddnsTimer cfgs);
  };

}
