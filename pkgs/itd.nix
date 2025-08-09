{
  buildGoModule,
  fetchFromGitea,
  libGL,
  pkg-config,
  xorg,
}:

buildGoModule rec {
  pname = "itd";
  version = "0.0.8";

  src = fetchFromGitea {
    domain = "gitea.arsenm.dev";
    owner = "Arsen6331";
    repo = "itd";
    rev = "v${version}";
    sha256 = "sha256-zLN8Sum5IDVK0wujHXZM4r1zLKUODrYvlFUpQQ9zyek=";
  };

  preConfigure = ''
    echo "v${version}" > version.txt
  '';

  vendorHash = "sha256-csy5AF6nCxewdPcSc7ZzLo1RH7+1GNg173ey93baCHE=";

  buildInputs = [
    libGL
    xorg.libX11
    xorg.libXcursor
    xorg.libXext
    xorg.libXi
    xorg.libXinerama
    xorg.libXrandr
    xorg.libXxf86vm
  ];

  nativeBuildInputs = [
    pkg-config
  ];

}
