module Test.Cache
  ( testFetchDogBreedsWithCache
  , testFetchBreedImagesWithCache
  ) where

import Prelude
import Api (Breed(..))
import Cache (CacheResult(..), fetchDogBreedsWithCache, fetchBreedImagesWithCache, initCache)
import Data.Either (Either(..))
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Aff (Aff)
import Effect.Class (liftEffect)
import Effect.Class.Console (log)
import Test.Assert as Assert

-- Test for fetching dog breeds
testFetchDogBreedsWithCache :: Aff Unit
testFetchDogBreedsWithCache = do
  log "Testing fetchDogBreedsWithCache..."
  cache <- liftEffect $ initCache
  result1 <- fetchDogBreedsWithCache cache
  result2 <- fetchDogBreedsWithCache cache
  liftEffect
    $ do
        expectMiss result1
        expectHit result2
  log "✓ testFetchDogBreedsWithCache test passed"

---- Test for fetching breed images
testFetchBreedImagesWithCache :: Aff Unit
testFetchBreedImagesWithCache = do
  log "Testing fetchBreedImagesWithCache..."
  cache <- liftEffect $ initCache
  let
    frenchBulldog = Breed { name: "bulldog", subBreed: Just "french" }
  let
    bostonBulldog = Breed { name: "bulldog", subBreed: Just "boston" }
  result1 <- fetchBreedImagesWithCache frenchBulldog cache
  result2 <- fetchBreedImagesWithCache frenchBulldog cache
  result3 <- fetchBreedImagesWithCache bostonBulldog cache
  liftEffect
    $ do
        expectMiss result1
        expectHit result2
        expectMiss result3
  log "✓ testFetchBreedImagesWithCache test passed"

expectHit :: forall a. Either String (CacheResult a) -> Effect Unit
expectHit (Left err) = Assert.assert' err false

expectHit (Right (Hit _)) = Assert.assert true

expectHit (Right (Miss _)) = Assert.assert' "Expected a cache hit, but got a miss" false

expectMiss :: forall a. Either String (CacheResult a) -> Effect Unit
expectMiss (Left err) = Assert.assert' err false

expectMiss (Right (Hit _)) = Assert.assert' "Expected a cache miss, but got a hit" false

expectMiss (Right (Miss _)) = Assert.assert true
