module Test.Main where

import Prelude
import Effect (Effect)
import Effect.Aff (launchAff_)
import Effect.Class.Console (log)
import Test.Api (testFetchDogBreeds, testFetchBreedImages)

main :: Effect Unit
main = launchAff_ do
  log "Running API tests..."
  testFetchDogBreeds
  log "\nTesting fetchBreedImages for 'hound'..."
  testFetchBreedImages "hound"