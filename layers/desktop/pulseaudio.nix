{ pkgs, ... }:

{

  hardware.pulseaudio = {
    enable = pkgs.lib.mkDefault true;
    zeroconf.discovery.enable = true;
    package = pkgs.pulseaudioFull;
  };

  environment.systemPackages = with pkgs; [
    pamixer
    pulsemixer
  ];

  services.acpid = let
    volumeStep = 1;
    gammaCorrection = 3;
    pauser = "beinke";
    pamixer = commands: ''
      /run/wrappers/bin/su ${pauser} -c 'XDG_RUNTIME_DIR=/run/user/$(${pkgs.coreutils}/bin/id -u ${pauser}) ${pkgs.pamixer}/bin/pamixer ${commands}'
    '';
  in {
    enable = true;
    handlers.volmute = {
      event = "button/mute";
      action = pamixer "--toggle-mute";
    };
    handlers.micmute = {
      event = "button/f20";
      action = pamixer "--default-source --toggle-mute";
    };
  };

}
