self: super:

with self;

{

  inxi-full = inxi.override { withRecommends = true; };

  spotifyd = super.spotifyd.override {rustPackages=self.rustPackages_1_45;};

  media_volume = callPackage ./media_volume.nix {};

  mpv_autospeed = ./mpv_autospeed.lua;

}
