{ runCommandLocal

, atk
, fetchFromGitHub
, gdk-pixbuf
, gtk3
, harfbuzz
, lib
, libnotify
, makeWrapper
, pango
, python310
, writeTextDir

, bs-install-dir ? null
}:

runCommandLocal "bs-oneclick" {
  src = fetchFromGitHub {
    owner = "Supreeeme";
    repo = "beatsaber-oneclick-linux";
    rev = "21674417b9e9a9a4b0cd27fd2815f05f8c22f3f9";
    hash = "sha256-dPB8QroisLPI3MmT7DdgctyzYhwLQCnlsTihoFWNndM=";
  };

  python = python310.withPackages (p: [ p.pygobject3 ]);

  bsPath = writeTextDir "bs-path.txt" bs-install-dir;
} ''
  . ${makeWrapper}/nix-support/setup-hook
  mkdir -p $out/bin $out $out/lib/bs-oneclick
  cp --reflink=auto $src/bs-oneclick.py $src/song_install.ui $bsPath/bs-path.txt $out/lib/bs-oneclick/
  makeWrapper $out/lib/bs-oneclick/bs-oneclick.py $out/bin/bs-oneclick --prefix PATH : $python/bin --prefix GI_TYPELIB_PATH : "${lib.makeSearchPathOutput "lib" "lib/girepository-1.0" [ atk gdk-pixbuf gtk3 harfbuzz pango libnotify ]}"
''
