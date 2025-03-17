module Test.Api where

import Prelude
import Effect (Effect)
import Effect.Class.Console (log)
import Effect.Aff (Aff, launchAff_)
import Data.Either (Either(..))
import Data.Array (length, take)
import Api (fetchDogBreeds, fetchBreedImages)

-- Test for fetching dog breeds
testFetchDogBreeds :: Aff Unit
testFetchDogBreeds = do
  log "Fetching dog breeds..."
  result <- fetchDogBreeds
  case result of
    Left err -> log $ "Test failed: " <> err
    Right breeds -> do
      log $ "Response received: " <> show result
      log $ "Successfully fetched " <> show (length breeds) <> " dog breeds"
      log $ "First few breeds: " <> show (take 5 breeds)

-- Test for fetching breed images
testFetchBreedImages :: String -> Aff Unit
testFetchBreedImages breed = do
  log $ "Fetching images for breed: " <> breed
  result <- fetchBreedImages breed
  case result of
    Left err -> log $ "Test failed: " <> err
    Right images -> do
      log $ "Response received: " <> show result
      log $ "Successfully fetched " <> show (length images) <> " images for " <> breed
      log $ "First few images: " <> show (take 3 images)