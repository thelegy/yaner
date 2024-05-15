{
  buildPythonPackage,
  fetchPypi,
  requests,
  pydantic,
}:
buildPythonPackage rec {
  pname = "easyeda2ato";
  version = "0.2.7";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-bHhBN+h9Vx9Q4wZVKxMzkEEXzV7hKoQz8i+JpkSFsYA=";
  };

  propagatedBuildInputs = [requests pydantic];
}
