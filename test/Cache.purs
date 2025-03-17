module Test.Cache where

import Prelude

import Api (Breed(..))
import Cache (CacheResult(..), fetchDogBreedsWithCache, fetchBreedImagesWithCache, initCache)
import Data.Either (Either(..))
import Data.Maybe (Maybe(..))
import Effect.Aff (Aff)
import Effect.Class (liftEffect)
import Effect.Class.Console (log)
import Test.Assert as Assert

-- Test for fetching dog breeds
testFetchDogBreedsWithCache :: Aff Unit
testFetchDogBreedsWithCache = do
  log "Testing fetchDogBreedsWithCache..."
  cache <- initCache
  result1 <- fetchDogBreedsWithCache cache
  result2 <- fetchDogBreedsWithCache cache
  case result1 of
    Left err -> liftEffect $ Assert.assert' err false
    Right (Miss _) -> liftEffect $ Assert.assert true
    Right (Hit _) -> liftEffect $ Assert.assert' "Expected a cache miss, but got a hit" false
  case result2 of
    Left err -> liftEffect $ Assert.assert' err false
    Right (Hit _) -> liftEffect $ Assert.assert true
    Right (Miss _) -> liftEffect $ Assert.assert' "Expected a cache hit, but got a miss" false
  log "✓ testFetchDogBreedsWithCache test passed"

---- Test for fetching breed images
testFetchBreedImagesWithCache :: Aff Unit
testFetchBreedImagesWithCache = do
  log "Testing fetchBreedImagesWithCache..."
  cache <- initCache
  let frenchBulldog = Breed { name: "bulldog", subBreed: Just "french" }
  let bostonBulldog = Breed { name: "bulldog", subBreed: Just "boston" }
  result1 <- fetchBreedImagesWithCache frenchBulldog cache
  result2 <- fetchBreedImagesWithCache frenchBulldog cache
  result3 <- fetchBreedImagesWithCache bostonBulldog cache
  case result1 of
    Left err -> liftEffect $ Assert.assert' err false
    Right (Miss _) -> liftEffect $ Assert.assert true
    Right (Hit _) -> liftEffect $ Assert.assert' "Expected a cache miss, but got a hit" false
  case result2 of
    Left err -> liftEffect $ Assert.assert' err false
    Right (Hit _) -> liftEffect $ Assert.assert true
    Right (Miss _) -> liftEffect $ Assert.assert' "Expected a cache hit, but got a miss" false
  case result3 of
    Left err -> liftEffect $ Assert.assert' err false
    Right (Miss _) -> liftEffect $ Assert.assert true
    Right (Hit _) -> liftEffect $ Assert.assert' "Expected a cache miss, but got a hit" false
  log "✓ testFetchBreedImagesWithCache test passed"
