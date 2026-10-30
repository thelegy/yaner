{ inputs, ... }:
{
  imports = [
    (inputs.flake-file.flakeModules.dendritic or {})
    # (inputs.den.flakeModule or {})
  ];

  # flake-file.inputs.den.url = "github:vic/den";
  # flake-file.inputs.flake-aspects.url = "github:vic/flake-aspects";
}
