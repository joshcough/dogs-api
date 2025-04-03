module Main (main) where

import Prelude
import BreedData (BreedData)
import Cache (initCache)
import Components.BreedApp as BreedApp
import Data.Maybe (Maybe(..))
import Data.Map as Map
import Effect (Effect)
import Effect.Aff (launchAff_)
import Effect.Class (liftEffect)
import Halogen.Aff as HA
import Halogen.VDom.Driver (runUI)
import HasDogBreeds (mkCachedBreedData)

main :: Effect Unit
main =
  launchAff_ do
    cacheRef <- liftEffect $ initCache ({ breeds: Nothing, images: Map.empty } :: BreedData)
    body <- HA.awaitBody
    _ <- runUI (BreedApp.component $ mkCachedBreedData cacheRef) unit body
    pure unit
