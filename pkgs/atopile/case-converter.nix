{
  buildPythonPackage,
  fetchPypi,
  pytest,
}:
buildPythonPackage rec {
  pname = "case-converter";
  version = "1.1.0";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-LtP8bj/6jWAfmjH/y8j70Z6utIZxp5qO8WOUZygkUQ4=";
  };

  nativeCheckInputs = [pytest];
}
