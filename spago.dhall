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
  , "effect"
  , "either"
  , "foldable-traversable"
  , "foreign-object"
  , "maybe"
  , "ordered-collections"
  , "prelude"
  , "refs"
  , "strings"
  , "tuples"
  , "web-dom"
  , "web-html"
  ]
, packages = ./packages.dhall
, sources = [ "src/**/*.purs", "test/**/*.purs" ]
}
