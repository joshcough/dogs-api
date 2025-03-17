{ name = "dog-breed-viewer"
, dependencies =
  [ "aff"
  , "affjax"
  , "affjax-node"
  , "argonaut-core"
  , "arrays"
  , "bifunctors"
  , "console"
  , "effect"
  , "either"
  , "foldable-traversable"
  , "foreign-object"
  , "maybe"
  , "prelude"
  , "tuples"
  , "web-dom"
  , "web-html"
  ]
, packages = ./packages.dhall
, sources = [ "src/**/*.purs", "test/**/*.purs" ]
}
