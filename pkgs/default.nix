self: super:

with self;

{

  inxi-full = inxi.override { withRecommends = true; };


  multimc = runCommand "multimc" {} ''
    mkdir -p $out/bin
    sed 's|${jdk}/bin|${openjdk14}/bin|' ${super.multimc}/bin/multimc > $out/bin/multimc
    chmod +x $out/bin/*
  '';



}
