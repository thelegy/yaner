{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "cs-firewall-bouncer";
  version = "0.0.28";

  src = fetchFromGitHub {
    owner = "crowdsecurity";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-Y1pCupCtYkOD6vKpcmM8nPlsGbO0kYhc3PC9YjJHeMw=";
  };

  vendorHash = "sha256-BA7OHvqIRck3LVgtx7z8qhgueaJ6DOMU8clvWKUCdqE=";
}
