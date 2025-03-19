{ name = "dog-breed-viewer"
, dependencies =
  [ "aff"
  , "affjax"
  , "affjax-node"
  , "argonaut-core"
  , "arrays"
  , "assert"
  , "bifunctors"
  , "console"
  , "const"
  , "datetime"
  , "effect"
  , "either"
  , "foldable-traversable"
  , "foreign-object"
  , "halogen"
  , "integers"
  , "maybe"
  , "ordered-collections"
  , "prelude"
  , "refs"
  , "strings"
  , "tuples"
  ]
, packages = ./packages.dhall
, sources = [ "src/**/*.purs", "test/**/*.purs" ]
}
