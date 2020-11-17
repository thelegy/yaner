self: super:

with self;

{

  haskell = super.haskell // {
    packageOverrides = hself: hsuper:
      ( import ./qbar self hself hsuper {} ) // {
      };
  };

  multimc = runCommand "multimc" {} ''
    mkdir -p $out/bin
    sed 's|${jdk}/bin|${openjdk14}/bin|' ${super.multimc}/bin/multimc > $out/bin/multimc
    chmod +x $out/bin/*
  '';

  qbar = haskellPackages.qbar;

  neovim-customized = callPackage ./neovim {};

}
