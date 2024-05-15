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
  quart,
  quart-cors,
  quart-schema,
  semver,
  toolz,
  unicorn,
  uvicorn,
  waitress,
  watchfiles,
  pyyaml,
}:
buildPythonPackage rec {
  pname = "atopile";
  version = "0.2.50";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-nUUynMECUl0j677ZpmX6qSmhFBWsVGdVg3k30XDbluI=";
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
    quart
    quart-cors
    quart-schema
    toolz
    unicorn
    uvicorn
    waitress
    watchfiles
    pyyaml
  ];
}
