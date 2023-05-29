{ lib, pkgs, ... }:

let
  rtpPort = 5004;
  rocSourcePort = 10001;
  rocRepairPort = 10002;
in {

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    systemWide = true;
    alsa.enable = true;
    pulse.enable = true;
  };
  systemd.services.pipewire.wantedBy = [ "multi-user.target" ];

  systemd.services.pipewire.environment.PIPEWIRE_DEBUG = "I,mod.rtp*:D";
  # systemd.services.wireplumber.environment.WIREPLUMBER_DEBUG = "3";

  environment.etc."pipewire/pipewire.conf.d/50-combine-output-20.conf".text = ''
    context.modules = [
      {
        name = libpipewire-module-combine-stream
        args = {
          combine.mode = sink
          node.name = "combine-output-20"
          node.description = "Output Proxy 2.0"
          combine.latency-compensate = false   # if true, match latencies by adding delays
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

  environment.etc."pipewire/pipewire.conf.d/60-roc-receiver-20.conf".text = ''
    context.modules = [
      {
        name = libpipewire-module-roc-source
        args = {
          local.ip = 0.0.0.0
          resampler.profile = medium
          sess.latency.msec = 50
          local.source.port = ${toString rocSourcePort}
          local.repair.port = ${toString rocRepairPort}
          source.name = "ROC Source"
          source.props = {
            node.name = "roc-source"
            target.object = "combine-sink-stereo"
          }
        }
      }
    ]
  '';

  networking.firewall.allowedUDPPorts = [ rtpPort rocSourcePort rocRepairPort ];
  networking.firewall.allowedTCPPorts = [ rocSourcePort rocRepairPort ];

  users.users.beinke = {
    extraGroups = [ "pipewire" ];
    packages = with pkgs; [
      pulseaudio
      pulsemixer
    ];
  };

}
