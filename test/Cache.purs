module Test.Cache
  ( testCacheMechanism
  ) where

import Prelude
import BreedData (BreedData, BreedFamily)
import Cache (Cache(..), CacheResult(..), fetchWithCache', initCache)
import Data.Either (Either(..))
import Data.Maybe (Maybe(..))
import Data.Map as Map
import Effect (Effect)
import Effect.Aff (Aff)
import Effect.Class (liftEffect)
import Effect.Class.Console (log)
import Test.Assert as Assert

-- Test the basic caching mechanism
testCacheMechanism :: Aff Unit
testCacheMechanism = do
  log "Testing cache hit/miss mechanism..."
  -- Create an empty cache
  cacheRef <- liftEffect $ initCache ({ breeds: Nothing, images: Map.empty } :: BreedData)
  -- Define test breed data with correct type
  let
    testBreeds =
      [ { name: "bulldog", subBreeds: [ "french", "english" ] }
      , { name: "shepherd", subBreeds: [ "german", "australian" ] }
      ] ::
        Array BreedFamily
  -- Define reader and writer functions
  let
    readCache (Cache breedData) = breedData.breeds

    writeCache breeds (Cache breedData) = Cache (breedData { breeds = Just breeds })

    -- Fake fetch function that always returns test data
    fetchTestBreeds = pure (Right testBreeds)
  -- First call should be a miss (not in cache)
  result1 <- fetchWithCache' readCache writeCache fetchTestBreeds cacheRef
  liftEffect $ expectMiss result1
  -- Second call should be a hit (found in cache)
  result2 <- fetchWithCache' readCache writeCache fetchTestBreeds cacheRef
  liftEffect $ expectHit result2
  -- Verify the data is correct in both cases
  liftEffect
    $ do
        verifyResultData testBreeds result1
        verifyResultData testBreeds result2
  log "✓ Cache hit/miss mechanism test passed"

-- Helper functions for assertions
expectHit :: forall a. Either String (CacheResult a) -> Effect Unit
expectHit (Left err) = Assert.assert' ("Expected a hit but got error: " <> err) false

expectHit (Right (Hit _)) = Assert.assert true

expectHit (Right (Miss _)) = Assert.assert' "Expected a cache hit, but got a miss" false

expectMiss :: forall a. Either String (CacheResult a) -> Effect Unit
expectMiss (Left err) = Assert.assert' ("Expected a miss but got error: " <> err) false

expectMiss (Right (Hit _)) = Assert.assert' "Expected a cache miss, but got a hit" false

expectMiss (Right (Miss _)) = Assert.assert true

verifyResultData :: forall a. Eq a => Show a => a -> Either String (CacheResult a) -> Effect Unit
verifyResultData expected (Right (Hit actual)) =
  Assert.assert' ("Expected hit data " <> show expected <> " but got " <> show actual)
    (expected == actual)

verifyResultData expected (Right (Miss actual)) =
  Assert.assert' ("Expected miss data " <> show expected <> " but got " <> show actual)
    (expected == actual)

verifyResultData _ (Left err) = Assert.assert' ("Cannot verify data on error: " <> err) false
