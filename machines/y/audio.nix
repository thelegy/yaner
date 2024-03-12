{ lib, pkgs, config, ... }:
with lib;

let
  rocSourcePortOut = 10001;
  rocRepairPortOut = 10002;
  rocSourcePortIn = 10011;
  rocRepairPortIn = 10012;
  clients = [ "sirrah" "th1" ];
in {

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    systemWide = true;
    alsa.enable = true;
    pulse.enable = true;
    configPackages = [
      (pkgs.writeTextDir "30-defaults.conf" ''
        context,properties = {
          default.clock.rate = 48000
          default.clock.allowed-rates = [ 48000, ]
        }
      '')
      (pkgs.writeTextDir "50-proxy-output-2_0.conf" ''
        context.modules = [
          {
            name = libpipewire-module-combine-stream
            args = {
              combine.mode = sink
              node.name = "proxy-output-2_0"
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
      '')
      (pkgs.writeTextDir "50-proxy-input-2_0.conf" ''
        context.modules = [
          {
            name = libpipewire-module-combine-stream
            args = {
              combine.mode = source
              node.name = "proxy-input-2_0"
              node.description = "Input Proxy 2.0"
              combine.latency-compensate = false   # if true, match latencies by adding delays
              combine.props = {
                audio.channels = 2
                audio.position = [ FL FR ]
              }
              stream.props = {
              }
              stream.rules = [
                {
                  matches = [
                    { node.name = "alsa_input.usb-JABRA_GN_2000_MS_USB-00.mono-fallback" }
                    { node.name = "alsa_input.usb-0b0e_Jabra_Link_380_08C8C2EBE145-00.mono-fallback" }
                  ]
                  actions = { create-stream = { } }
                }
              ]
            }
          }
        ]
      '')
      (pkgs.writeTextDir "60-roc-receiver-2_0.conf" ''
        context.modules = [
          {
            name = libpipewire-module-roc-source
            args = {
              local.ip = ${head (splitString "/" config.wat.thelegy.wg-net.rtlan.thisNode.address)}
              resampler.profile = medium
              sess.latency.msec = 60
              local.source.port = ${toString rocSourcePortOut}
              local.repair.port = ${toString rocRepairPortOut}
              source.name = "ROC Source"
              source.props = {
                node.name = "roc-source"
                target.object = "proxy-output-2_0"
              }
            }
          }
        ]
      '')
      (pkgs.writeTextDir "60-roc-sender-2_0.conf" ''
        context.modules = [
        ${concatMapStringsSep "\n" (client: ''
          {
            name = libpipewire-module-roc-sink
            args = {
              remote.ip = ${head (splitString "/" config.wat.thelegy.wg-net.rtlan.nodes.${client}.address)}
              remote.source.port = ${toString rocSourcePortIn}
              remote.repair.port = ${toString rocRepairPortIn}
              sink.props = {
                node.name = "roc-sink-${client}"
                media.class = "Stream/Input/Audio"
              }
            }
          },
        '') clients}
        ]
      '')
    ];
  };
  systemd.services.pipewire.wantedBy = [ "multi-user.target" ];

  # systemd.services.pipewire.environment.PIPEWIRE_DEBUG = "W,mod.combine*:D,mod.roc-sink:D";
  # systemd.services.wireplumber.environment.WIREPLUMBER_DEBUG = "3";

  systemd.services.wireplumber.postStart = ''
    ${pkgs.coreutils}/bin/sleep 5s
    ${concatMapStringsSep "\n" (client: ''
      ${pkgs.pipewire}/bin/pw-link proxy-input-2_0:capture_FL roc-sink-${client}:send_FL || true
      ${pkgs.pipewire}/bin/pw-link proxy-input-2_0:capture_FR roc-sink-${client}:send_FR || true
    '') clients}
  '';

  networking.nftables.firewall = {

    rules.rtlan-audio-server = {
      from = [ "rtlan" ];
      to = [ "fw" ];
      allowedUDPPorts = [ rocSourcePortOut rocRepairPortOut ];
    };

  };

  users.users.beinke = {
    extraGroups = [ "pipewire" ];
    packages = with pkgs; [
      pulseaudio
      pulsemixer
    ];
  };

}
