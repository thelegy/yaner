
{ mkTrivialModule
, pkgs
, ... }:

mkTrivialModule {

  environment.systemPackages = with pkgs; [
    pulsemixer
  ];

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

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
    #handlers.voldown = {
    #  event = "button/volumedown";
    #  action = pamixer "--gamma ${toString gammaCorrection} --decrease ${toString volumeStep} --unmute";
    #};
    #handlers.volup = {
    #  event = "button/volumeup";
    #  action = pamixer "--gamma ${toString gammaCorrection} --increase ${toString volumeStep} --unmute";
    #};
    handlers.micmute = {
      event = "button/f20";
      action = pamixer "--default-source --toggle-mute";
    };
  };

}
