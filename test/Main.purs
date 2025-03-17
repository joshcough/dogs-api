module Test.Main where

import Prelude

import Effect (Effect)
import Effect.Aff (launchAff_)
import Test.Api (testFetchDogBreeds, testFetchBreedImages)

main :: Effect Unit
main = launchAff_ do
  testFetchDogBreeds
  testFetchBreedImages
