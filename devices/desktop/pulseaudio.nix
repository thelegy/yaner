{ config, options, pkgs, ... }:

{

  hardware.pulseaudio.enable = true;

  environment.systemPackages = with pkgs; [
    pamixer
    ncpamixer
  ];

  services.acpid = let
    volumeStep = 5;
    pauser = "beinke";
    pamixer = commands: ''
      /run/wrappers/bin/su ${pauser} -c 'XDG_RUNTIME_DIR=/run/user/$(${pkgs.coreutils}/bin/id -u ${pauser}) ${pkgs.pamixer}/bin/pamixer ${commands}'
    '';
  in {
    enable = true;
    handlers.volmute = { event = "button/mute";       action = pamixer "--toggle-mute"; };
    handlers.voldown = { event = "button/volumedown"; action = pamixer "--decrease ${toString volumeStep} --unmute"; };
    handlers.volup   = { event = "button/volumeup";   action = pamixer "--increase ${toString volumeStep} --unmute"; };
    handlers.micmute = { event = "button/f20";        action = pamixer "--default-source --toggle-mute"; };
  };

}
