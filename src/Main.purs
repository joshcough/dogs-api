module Main (main) where

import Prelude
import AppM (AppM, runAppM)
import BreedData (emptyBreedData)
import Components.BreedApp as BreedApp
import Effect (Effect)
import Effect.Class (liftEffect)
import Effect.Ref (new)
import Halogen as H
import Halogen.Aff as HA
import Halogen.VDom.Driver (runUI)

main :: Effect Unit
main = do
  HA.runHalogenAff do
    cacheRef <- liftEffect $ new emptyBreedData
    body <- HA.awaitBody
    let
      component = H.hoist (runAppM cacheRef) (BreedApp.component :: _ AppM)
    _ <- runUI component unit body
    pure unit
