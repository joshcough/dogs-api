{ name = "my-purescript-app"
, dependencies =
  [ "console"
  , "effect"
  , "maybe"
  , "prelude"
  , "web-dom"
  , "web-html"
  ]
, packages = ./packages.dhall
, sources = [ "src/**/*.purs" ]
}