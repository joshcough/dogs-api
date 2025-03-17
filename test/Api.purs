module Test.Api where

import Prelude
import Api (BreedFamily, Breed(..), fetchDogBreeds, fetchBreedImages)
import Data.Array (elem, length, null, all)
import Data.Either (Either(..), isRight)
import Data.Maybe (Maybe(..), isJust)
import Data.String (indexOf)
import Data.String.Pattern (Pattern(..))
import Effect.Aff (Aff)
import Effect.Class (liftEffect)
import Effect.Class.Console (log)
import Test.Assert as Assert

-- Test for fetching dog breeds
testFetchDogBreeds :: Aff Unit
testFetchDogBreeds = do
  log "Testing fetchDogBreeds..."
  result <- fetchDogBreeds
  liftEffect $ Assert.assert (isRight result)
  case result of
    Left err -> do
      log $ "Unexpected error: " <> err
      liftEffect $ Assert.assert false
    Right breeds -> do
      liftEffect $ Assert.assert (not $ null breeds)
      liftEffect $ Assert.assert (length breeds >= 100)
      liftEffect $ Assert.assert $ elem "labrador" (map getBreedFamilyName breeds)
      liftEffect $ Assert.assert $ elem "beagle" (map getBreedFamilyName breeds)
      log "✓ fetchDogBreeds test passed"

-- Test for fetching breed images
testFetchBreedImages :: Aff Unit
testFetchBreedImages = do
  log "Testing fetchBreedImages..."
  let
    bulldogReq = Breed { name: "bulldog", subBreed: Just "french" }
  result <- fetchBreedImages bulldogReq
  liftEffect $ Assert.assert (isRight result)
  case result of
    Left err -> do
      log $ "Unexpected error: " <> err
      liftEffect $ Assert.assert false
    Right images -> do
      liftEffect $ Assert.assert (not $ null images)
      liftEffect $ Assert.assert (length images >= 5)
      let
        allValidUrls = all isValidImageUrl images
      liftEffect $ Assert.assert allValidUrls
      log "✓ fetchBreedImages test passed"

getBreedFamilyName :: BreedFamily -> String
getBreedFamilyName breedFamily = breedFamily.name

isValidImageUrl :: String -> Boolean
isValidImageUrl url = startsWith "https://images.dog.ceo" url && contains "jpg" url

startsWith :: String -> String -> Boolean
startsWith prefix str = indexOf (Pattern prefix) str == Just 0

contains :: String -> String -> Boolean
contains substr str = isJust (indexOf (Pattern substr) str)
