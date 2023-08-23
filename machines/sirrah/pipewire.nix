{ lib, pkgs, config, ... }:
with lib;

{

  wat.thelegy.rtlan-net.enable = true;
  wat.thelegy.roc-client = {
    enable = true;
    serverAddress = head (splitString "/" config.wat.thelegy.wg-net.rtlan.nodes.y.address);
    localAddress = head (splitString "/" config.wat.thelegy.wg-net.rtlan.thisNode.address);
  };

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.support32Bit = true;
    jack.enable = true;
  };

  # systemd.services.pipewire.environment.PIPEWIRE_DEBUG = "W,mod.combine*:D,mod.roc-sink:D";
  # systemd.services.wireplumber.environment.WIREPLUMBER_DEBUG = "3";

  environment.etc."pipewire/pipewire.conf.d/50-proxy-output-2_0.conf".text = ''
    context.modules = [
      {
        name = libpipewire-module-combine-stream
        args = {
          combine.mode = sink
          node.name = "proxy-output-2_0"
          node.description = "Output Proxy 2.0"
          combine.latency-compensate = true   # if true, match latencies by adding delays
          combine.props = {
            audio.position = [ FL FR ]
          }
          stream.props = {
          }
          stream.rules = [
            {
              matches = [ { media.class = "Audio/Sink" } ]
              actions = { create-stream = { } }
            }
          ]
        }
      }
    ]
  '';

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [ xdg-desktop-portal-wlr ];
  };
  environment.sessionVariables.GTK_USE_PORTAL = "1";

}
