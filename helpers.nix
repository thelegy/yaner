rec {

  # id :: a -> a
  id = value: value;

  # not :: Bool -> Bool
  # not :: (a -> Bool) -> a -> Bool
  not = value: with builtins;
    if isBool value then
      ! value
    else if isFunction value then
      x: ! (value x)
    else
      throw ("value is a " + typeOf value + " while a Boolean or a Function was expected");


  # filterAnd :: [ (a -> Bool) ] -> a -> Bool
  filterAnd = lambdas: value: with builtins;
    all (lambda: lambda value) lambdas;


  # filterOr :: [ (a -> Bool) ] -> a -> Bool
  filterOr = lambdas: value: with builtins;
    any (lambda: lambda value) lambdas;


  # readFilterDir :: ({name:String, path:Path, type:String, ...} -> Bool) -> Path -> [ String ]
  readFilterDir = lambda: path: with builtins;
  let
    dirContents = readDir path;
    filterFunc = name: lambda rec {
      inherit name;
      path = path + "/${name}";
      type = dirContents.${name};
    };
  in filter filterFunc (attrNames dirContents);


  # filterDirHidden :: {name:String, ...} -> Bool
  filterDirHidden = { name, ... }:
    (builtins.substring 0 1 name) == ".";


  # filterDirDirs :: {type:String, ...} -> Bool
  filterDirDirs = { type, ... }:
    type == "directory";


  # filterDirFiles :: {type:String, ...} -> Bool
  filterDirFiles = { type, ... }:
    type == "regular";


  # filterDirSymlinks :: {type:String, ...} -> Bool
  filterDirSymlinks = { type, ... }:
    type == "symlink";

  # filterAttrs :: ({key:String, value:a} -> Bool) -> { *: a } -> { *: a }
  filterAttrs = lambda: set: with builtins;
  let
    filterFunc = name: lambda {key=name;value=set.${name};};
    foldFunc = x: y: x // {${y}=set.${y};};
  in foldl' foldFunc {} (filter filterFunc (attrNames set));

  # keysToAttrs :: ( String -> a ) -> [ String ] -> { *: a }
  keysToAttrs = lambda: strings:
    builtins.listToAttrs (map (k: {
      name = k;
      value = lambda k;
    }) strings);

  # isMaybe :: a -> Bool
  isMaybe = m: with builtins;
    if not isAttrs m then false else
    if not (hasAttr "isMaybe") m then false else
    if not isBool m.isMaybe then false else
    m.isMaybe;

  # Just :: a -> Maybe a
  Just = a: {isMaybe = true; hasValue = true; value = a;};

  # Nothing :: Maybe a
  Nothing = {isMaybe = true; hasValue = false;};

  # maybe :: b -> (a -> b) -> Maybe a -> b
  maybe = default: transform: m:
    if not isMaybe m then
      throw "maybe: ${m} is not a Maybe."
    else
      if m.hasValue then
        transform m.value
      else
        default
    ;

  # maybeToList :: Maybe a -> [ a ]
  maybeToList = m:
    if not isMaybe m then
      throw "maybeToList: ${m} is not a Maybe."
    else if m.hasValue then
      [ m.value ]
    else
      [];

  # toExistingPath :: Path -> Maybe Path
  toExistingPath = path: with builtins;
    if pathExists path then Just path else Nothing;

}
