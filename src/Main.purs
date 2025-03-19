module Main (main) where

import Prelude
import Cache (initCache)
import Components.BreedApp as BreedApp
import Effect (Effect)
import Effect.Aff (launchAff_)
import Effect.Class (liftEffect)
import Halogen.Aff as HA
import Halogen.VDom.Driver (runUI)

main :: Effect Unit
main =
  launchAff_ do
    cache <- liftEffect initCache
    body <- HA.awaitBody
    _ <- runUI (BreedApp.component cache) unit body
    pure unit
