{
  config,
  lib,
  liftToNamespace,
  mkModule,
  pkgs,
  ...
}:
with lib; let
  toYAML = lib.generators.toYAML {};
  yaml = pkgs.formats.yaml {};
  configDir = "crowdsec";
  lapi_credentials_path = "/etc/crowdsec/local_api_credentials.yaml";
  hub = pkgs.fetchFromGitHub {
    owner = "crowdsecurity";
    repo = "hub";
    rev = "v1.5.5";
    hash = "sha256-04t+lZj51weHbgY0ygmARMa/CMHu1imHLFH981st9Fc=";
  };
in
  mkModule {
    options = liftToNamespace {
      lapi = {
        enable = mkEnableOption "crowdsec local api server";
      };
      sopsLapiCredentialsFile = mkOption {
        type = types.str;
        default = "crowdsec-lapi-credentials";
      };
      sopsBouncerCredentialsFile = mkOption {
        type = types.str;
        default = "crowdsec-bouncer-credentials";
      };
    };

    config = cfg: let
      etcConfig = {
        "${configDir}/config.yaml".text = toYAML {
          common = {
            daemonize = true;
            log_media = "stdout";
            log_level = "info";
          };
          config_paths = {
            config_dir = "/etc/${configDir}";
            data_dir = "\$STATE_DIRECTORY";
            hub_dir = "/etc/static/${configDir}/hub";
          };
          crowdsec_service = {
            enable = true;
            acquisition_dir = "/etc/${configDir}/acquisition";
          };
          cscli = {
            output = "human";
          };
          api.client = {
            credentials_path = lapi_credentials_path;
          };
          prometheus = {
            enabled = true;
            level = "full";
            listen_addr = "127.0.0.1";
            listen_port = 6060;
          };
        };

        "${configDir}/patterns".source = "${pkgs.crowdsec}/share/crowdsec/config/patterns";
        "${configDir}/simulation.yaml".source = "${pkgs.crowdsec}/share/crowdsec/config/simulation.yaml";
        "${configDir}/profiles.yaml".source = "${pkgs.crowdsec}/share/crowdsec/config/profiles.yaml";

        "${configDir}/acquisition/journal.yaml".text = toYAML {
          source = "journalctl";
          journalctl_filter = [
            "_SYSTEMD_UNIT=sshd.service"
          ];
          labels.type = "syslog";
        };

        "${configDir}/local_api_credentials.yaml".text = toYAML {
          url = "http://127.0.0.1:8080/";
        };
        "${configDir}/local_api_credentials.yaml.local".source = config.sops.secrets.${cfg.sopsLapiCredentialsFile}.path;

        "${configDir}/hub".source = hub;
      };

      confDir = pkgs.runCommandLocal "crowdsec-lapi-config" {} ''
        mkdir $out
        ln -s ${pkgs.crowdsec}/share/crowdsec/config/patterns $out/
        ln -s ${pkgs.crowdsec}/share/crowdsec/config/simulation.yaml $out/
        ln -s ${pkgs.crowdsec}/share/crowdsec/config/profiles.yaml $out/
      '';
      mainConfig = yaml.generate "crowdsec-lapi.yaml" {
        common = {
          daemonize = true;
          log_media = "stdout";
          log_level = "info";
        };
        config_paths = {
          config_dir = "${confDir}";
          data_dir = "\$STATE_DIRECTORY";
        };
        crowdsec_service = {
          enable = false;
        };
        db_config = {
          type = "sqlite";
          db_path = "\$STATE_DIRECTORY/crowdsec.db";
          use_wal = true;
        };
        api.client = {
          insecure_skip_verify = false;
          credentials_path = lapi_credentials_path;
        };
        api.server = {
          enable = true;
          listen_uri = "127.0.0.1:8080";
          profiles_path = "${confDir}/profiles.yaml";
        };
        prometheus = {
          enabled = true;
          level = "full";
          listen_addr = "127.0.0.1";
          listen_port = 6059;
        };
      };
      cscli-lapi = pkgs.writeScriptBin "cscli-lapi" ''
        #!/bin/sh
        STATE_DIRECTORY=/var/lib/crowdsec-lapi exec ${pkgs.crowdsec}/bin/cscli -c ${mainConfig} "$@"
      '';
    in {
      environment.systemPackages = mkMerge [
        [pkgs.crowdsec]
        (mkIf cfg.lapi.enable [cscli-lapi])
      ];
      environment.etc = etcConfig;

      users.groups.crowdsec = {};

      sops.secrets.${cfg.sopsLapiCredentialsFile} = {
        format = "yaml";
        mode = "0640";
        group = "crowdsec";
        restartUnits = ["crowdsec.service" "crowdsec-lapi.service"];
      };

      sops.secrets.${cfg.sopsBouncerCredentialsFile} = {
        format = "yaml";
        mode = "0640";
        group = "crowdsec";
        restartUnits = ["cs-firewall-bouncer.service"];
      };

      systemd.services.crowdsec-lapi =
        mkIf cfg.lapi.enable
        {
          description = "Crowdsec local api server";
          wantedBy = ["multi-user.target"];

          serviceConfig = {
            Type = "notify";
            ExecStart = "${pkgs.crowdsec}/bin/crowdsec -c ${mainConfig}";
            Environment = "LC_ALL=C LANG=C";
            Restart = "always";
            RestartSec = 60;
            DynamicUser = true;
            StateDirectory = "crowdsec-lapi";
            SyslogIdentifier = "crowdsec-lapi";
          };
        };

      systemd.services.crowdsec-agent = let
        preStartScript = pkgs.writeScript "crowdsec-agent-pre-start" ''
          #!/bin/sh
          set -e

          rm -rf /etc/crowdsec/{parsers,scenarios}/* || true
          # mkdir -p /etc/crowdsec/{parsers,scenarios}

          ${pkgs.crowdsec}/bin/cscli parsers install crowdsecurity/syslog-logs crowdsecurity/sshd-logs crowdsecurity/geoip-enrich

          ${pkgs.crowdsec}/bin/cscli scenarios install crowdsecurity/ssh-bf crowdsecurity/ssh-slow-bf
        '';
      in {
        description = "Crowdsec agent";
        wantedBy = ["multi-user.target"];

        restartTriggers = [(builtins.toJSON etcConfig)];

        serviceConfig = {
          Type = "notify";
          ExecStartPre = [
            "+${pkgs.coreutils}/bin/mkdir -p /etc/crowdsec/{parsers,scenarios}"
            "!${preStartScript}"
          ];
          ExecStart = "${pkgs.crowdsec}/bin/crowdsec";
          Environment = "LC_ALL=C LANG=C";
          Restart = "always";
          RestartSec = 10;
          DynamicUser = true;
          ReadWritePaths = [
            "/etc/crowdsec/parsers"
            "/etc/crowdsec/scenarios"
          ];
          SupplementaryGroups = [
            "crowdsec"
            "systemd-journal"
          ];
          StateDirectory = "crowdsec";
        };
      };

      networking.nftables.ruleset = ''
        table inet firewall {
          set crowdsec-blacklists {
            type ipv4_addr
            flags timeout
          }
          set crowdsec6-blacklists {
            type ipv6_addr
            flags timeout
          }
        }
      '';

      networking.nftables.firewall.zones.crowdsec-ban = {
        ingressExpression = [
          "ip saddr @crowdsec-blacklists"
          "ip6 saddr @crowdsec6-blacklists"
        ];
        egressExpression = [
          "ip daddr @crowdsec-blacklists"
          "ip6 daddr @crowdsec6-blacklists"
        ];
      };
      networking.nftables.firewall.rules.crowdsec-ban = {
        from = ["crowdsec-ban"];
        to = "all";
        ruleType = "ban";
        extraLines = [
          "counter drop"
        ];
      };

      systemd.services.cs-firewall-bouncer = let
        configFile = yaml.generate "cs-firewall-bouncer.yaml" {
          mode = "nftables";
          log_mode = "stdout";
          update_frequency = "10s";
          api_url = "http://127.0.0.1:8080";
          nftables = {
            ipv4 = {
              set-only = true;
              table = "firewall";
            };
            ipv6 = {
              set-only = true;
              table = "firewall";
            };
          };
        };
        confDir = pkgs.runCommandLocal "cs-firewall-bounder-config" {} ''
          mkdir $out
          ln -s ${configFile} $out/config.yaml
          ln -s ${config.sops.secrets.${cfg.sopsBouncerCredentialsFile}.path} $out/config.yaml.local
        '';
      in {
        wantedBy = ["multi-user.target"];
        after = ["nftables.service"];

        unitConfig = {
          PartOf = "nftables.service";
          ReloadPropagatedFrom = "nftables.service";
        };
        serviceConfig = {
          Type = "notify";
          NotifyAccess = "all";
          ExecStart = "${pkgs.cs-firewall-bouncer}/bin/cs-firewall-bouncer -c ${confDir}/config.yaml";
          ExecReload = "!${config.systemd.package}/bin/systemctl restart cs-firewall-bouncer.service";
          AmbientCapabilities = [
            "CAP_NET_ADMIN"
          ];
          SupplementaryGroups = [
            "crowdsec"
          ];
          Restart = "always";
          RestartSec = 10;
          DynamicUser = true;
        };
      };
    };
  }
