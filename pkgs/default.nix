self: super:

with self;

{

  inxi-full = inxi.override { withRecommends = true; };

  media_volume = callPackage ./media_volume.nix {};

  mpv_autospeed = ./mpv_autospeed.lua;

}
