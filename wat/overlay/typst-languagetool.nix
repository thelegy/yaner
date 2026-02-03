{
  rustPlatform,
  fetchFromGitHub,
  openssl,
  pkg-config,
  lsp ? false,
}:
rustPlatform.buildRustPackage rec {
  pname = "typst-languagetool";
  version = "head";

  src = fetchFromGitHub {
    owner = "thelegy";
    repo = pname;
    rev = "852088228962";
    hash = "sha256-9JTmmekqITD3EXkYHaV5QWn0IrXQQ8I0l+tjAGMiLiE=";
  };

  cargoHash = "sha256-CsF4lzLbsWTxj5LqrmYxe48C7fbREo6hAMpDdbQyRpk=";

  buildAndTestSubdir = if lsp then "lsp" else "cli";
  buildFeatures = [ "remote-server" ];

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl ];
}
