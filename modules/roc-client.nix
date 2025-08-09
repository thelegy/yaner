{
  lib,
  liftToNamespace,
  mkModule,
  pkgs,
  ...
}:
with lib;

mkModule {

  options = cfg: liftToNamespace {

    serverAddress = mkOption {
      type = types.str;
    };

    localAddress = mkOption {
      type = types.str;
    };

    sourcePortOut = mkOption {
      type = types.port;
      default = 10001;
    };

    repairPortOut = mkOption {
      type = types.port;
      default = 10002;
    };

    sourcePortIn = mkOption {
      type = types.port;
      default = 10011;
    };

    repairPortIn = mkOption {
      type = types.port;
      default = 10012;
    };

  };

  config = cfg: {
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
        allowedUDPPorts = [ cfg.sourcePortIn cfg.repairPortIn ];
      };

    };

  };

}
