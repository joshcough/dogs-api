module Test.Main where

import Prelude
import Effect (Effect)
import Effect.Aff (launchAff_)
import Test.Cache (testCacheMechanism)
import Test.DogsApi (testFetchDogBreeds, testFetchBreedImages)
import Test.PaginationState (testPaginationState)

main :: Effect Unit
main =
  launchAff_ do
    testFetchDogBreeds
    testFetchBreedImages
    testCacheMechanism
    testPaginationState
