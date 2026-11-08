{ wat, ... }:
{
  flake.nixosModules.roc-client = wat.mkModule [ "roc-client" ] (
    {
      cfg,
      lib,
      pkgs,
      ...
    }:

    {

      namespaceOptions = {

        serverAddress = lib.mkOption {
          type = lib.types.str;
        };

        localAddress = lib.mkOption {
          type = lib.types.str;
        };

        sourcePortOut = lib.mkOption {
          type = lib.types.port;
          default = 10001;
        };

        repairPortOut = lib.mkOption {
          type = lib.types.port;
          default = 10002;
        };

        sourcePortIn = lib.mkOption {
          type = lib.types.port;
          default = 10011;
        };

        repairPortIn = lib.mkOption {
          type = lib.types.port;
          default = 10012;
        };

      };

      config = {
        services.pipewire.configPackages = [
          (pkgs.writeTextDir "share/pipewire/pipewire.conf.d/60-roc-sender-20.conf" ''
            context.modules = [
              {
                name = libpipewire-module-roc-sink
                args = {
                  remote.ip = ${cfg.serverAddress}
                  remote.source.port = ${toString cfg.sourcePortOut}
                  remote.repair.port = ${toString cfg.repairPortOut}
                  sink.name = "ROC Sink"
                  sink.props = {
                    node.name = "roc-sink"
                  }
                }
              }
            ]
          '')
          (pkgs.writeTextDir "share/pipewire/pipewire.conf.d/60-roc-receiver-20.conf" ''
            context.modules = [
              {
                name = libpipewire-module-roc-source
                args = {
                  local.ip = ${cfg.localAddress}
                  resampler.profile = medium
                  sess.latency.msec = 50
                  local.source.port = ${toString cfg.sourcePortIn}
                  local.repair.port = ${toString cfg.repairPortIn}
                  source.name = "ROC Sink"
                  source.props = {
                    media.class = "Audio/Source"
                    node.name = "roc-source"
                    target.object = "combine-sink-stereo"
                  }
                }
              }
            ]
          '')
        ];

        networking.nftables.firewall = {

          rules.rtlan-audio-client = {
            from = [ "rtlan" ];
            to = [ "fw" ];
            allowedUDPPorts = [
              cfg.sourcePortIn
              cfg.repairPortIn
            ];
          };

        };

      };

    }

  );
}
