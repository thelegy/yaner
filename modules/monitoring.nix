{
  lib,
  liftToNamespace,
  mkModule,
  ...
}:
with lib;
mkModule {
  options =
    cfg:
    liftToNamespace {
      remoteWriteUrl = mkOption {
        type = types.str;
        default = "https://prometheus.0jb.de/api/v1/write";
      };
      lokiUrl = mkOption {
        type = types.nullOr types.str;
        default = "https://loki.0jb.de/loki/api/v1/push";
      };
    };

  config = cfg: {
    services.alloy = {
      enable = true;
      configPath = "/etc/alloy";
    };

    environment.etc."alloy/config.alloy".text = ''
      prometheus.remote_write "default" {
        endpoint {
          url = "${cfg.remoteWriteUrl}"
        }
      }

      loki.write "default" {
        endpoint {
          url = "${cfg.lokiUrl}"
        }
      }

      loki.relabel "journal" {
        forward_to = [loki.write.default.receiver]
        rule {
          source_labels = ["__journal__priority"]
          target_label  = "priority"
        }
        rule {
          source_labels = ["__journal__systemd_slice"]
          target_label  = "slice"
        }
        rule {
          source_labels = ["__journal_syslog_facility"]
          target_label  = "syslogFacility"
        }
        rule {
          source_labels = ["__journal_syslog_identifier"]
          target_label  = "syslogIdentifier"
        }
        rule {
          source_labels = ["__journal__uid"]
          target_label  = "uid"
        }
        rule {
          source_labels = ["__journal__systemd_unit"]
          target_label  = "unit"
        }
      }

      loki.source.journal "journal" {
        forward_to = [loki.relabel.journal.receiver]
        labels = {
          job = "journal",
          job = env("HOSTNAME"),
        }
        max_age = "12h"
      }
    '';

    environment.etc."alloy/self-exporter.alloy".text = ''
      prometheus.exporter.self "self" {
      }

      prometheus.scrape "self" {
        targets = prometheus.exporter.self.self.targets
        forward_to = [prometheus.remote_write.default.receiver]
      }
    '';

    environment.etc."alloy/unix-exporter.alloy".text = ''
      prometheus.exporter.unix "self" {
        enable_collectors = [
          "systemd",
        ]
      }

      prometheus.scrape "unix" {
        targets = prometheus.exporter.unix.self.targets
        forward_to = [prometheus.remote_write.default.receiver]
      }
    '';
  };
}
