{
  buildPythonPackage,
  fetchPypi,
  requests,
  pydantic,
}:
buildPythonPackage rec {
  pname = "easyeda2ato";
  version = "0.2.6";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-4p5KxiZgbjWtwZO2eFo7ym5cKfKR6RzX5uS6RqaN40g=";
  };

  propagatedBuildInputs = [requests pydantic];
}
