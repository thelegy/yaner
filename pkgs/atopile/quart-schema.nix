{
  buildPythonPackage,
  fetchPypi,
  poetry-core,
  pydantic,
  pyhumps,
  quart,
}:
buildPythonPackage rec {
  pname = "quart_schema";
  version = "0.19.1";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-LD5rLYOLIgqA3siMiaoysvCAxVJ+w+sxobWBlCN1MDc=";
  };

  nativeBuildInputs = [poetry-core];

  propagatedBuildInputs = [pydantic pyhumps quart];
}
