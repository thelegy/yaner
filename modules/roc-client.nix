{ mkModule, liftToNamespace, lib, ... }:
with lib;

mkModule {

  options = cfg: liftToNamespace {

    serverAddress = mkOption {
      type = types.str;
    };

    sourcePort = mkOption {
      type = types.port;
      default = 10001;
    };

    repairPort = mkOption {
      type = types.port;
      default = 10001;
    };

  };

  config = cfg: {

  environment.etc."pipewire/pipewire.conf.d/60-roc-sender-20.conf".text = ''
    context.modules = [
      {
        name = libpipewire-module-roc-sink
        args = {
          remote.ip = ${cfg.serverAddress}
          remote.source.port = ${toString cfg.sourcePort}
          remote.repair.port = ${toString cfg.repairPort}
          sink.name = "ROC Sink"
          sink.props = {
             node.name = "roc-sink"
          }
        }
      }
    ]
  '';

  };

}
