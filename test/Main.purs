module Test.Main where

import Prelude
import Effect (Effect)
import Effect.Aff (launchAff_)
import Test.Api (testFetchDogBreeds, testFetchBreedImages)
import Test.Cache (testFetchDogBreedsWithCache, testFetchBreedImagesWithCache)
import Test.PaginationState (testPaginationState)

main :: Effect Unit
main =
  launchAff_ do
    testFetchDogBreeds
    testFetchBreedImages
    testFetchDogBreedsWithCache
    testFetchBreedImagesWithCache
    testPaginationState
