{
  buildPythonPackage,
  fetchPypi,
  antlr4-python3-runtime,
  case-converter,
  deepdiff,
  easyeda2ato,
  eseries,
  fastapi,
  flask,
  flask-cors,
  gitpython,
  hatch-vcs,
  hatchling,
  igraph,
  jinja2,
  natsort,
  networkx,
  pandas,
  pint,
  pygls,
  rich,
  ruamel-yaml,
  schema,
  scipy,
  semver,
  toolz,
  unicorn,
  uvicorn,
  waitress,
  watchfiles,
}:
buildPythonPackage rec {
  pname = "atopile";
  version = "0.2.46";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-4eyNlZt5unxU6EW7oStuxpYE2/QkPx4DzRpE0pUDcRA=";
  };

  nativeBuildInputs = [
    hatchling
    hatch-vcs
  ];

  propagatedBuildInputs = [
    antlr4-python3-runtime
    case-converter
    deepdiff
    easyeda2ato
    eseries
    fastapi
    flask
    flask-cors
    gitpython
    igraph
    jinja2
    natsort
    networkx
    pandas
    pint
    pygls
    rich
    ruamel-yaml
    schema
    scipy
    semver
    toolz
    unicorn
    uvicorn
    waitress
    watchfiles
  ];
}
