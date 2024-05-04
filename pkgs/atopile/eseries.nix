{
  buildPythonPackage,
  fetchPypi,
  docopt_subcommands,
  future,
}:
buildPythonPackage rec {
  pname = "eseries";
  version = "1.2.1";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-BhIrGBQaKK53WLtCORsWO8QgOf17kdNjNjHAyPowDjY=";
  };

  propagatedBuildInputs = [docopt_subcommands future];

  doCheck = false;
}
