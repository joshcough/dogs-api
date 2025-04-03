module Test.Cache where

import Prelude

import BreedData (BreedData, BreedFamily)
import Cache (Cache(..), CacheResult(..), fetchWithCache', initCache)
import Data.Either (Either(..), isRight)
import Data.Maybe (Maybe(..))
import Data.Map as Map
import Effect.Aff (Aff)
import Effect.Class (liftEffect)
import Effect.Ref as Ref
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual, shouldSatisfy, fail)

spec :: Spec Unit
spec = describe "Cache Module" do

  describe "fetchWithCache'" do
    it "should return a miss on first call and fetch data" do
      -- Setup cache and test data
      cacheRef <- liftEffect $ initCache ({ breeds: Nothing, images: Map.empty } :: BreedData)
      let testBreeds = [
            { name: "bulldog", subBreeds: [ "french", "english" ] },
            { name: "shepherd", subBreeds: [ "german", "australian" ] }
          ] :: Array BreedFamily

      -- Define reader and writer functions
      let readCache (Cache breedData) = breedData.breeds
          writeCache breeds (Cache breedData) = Cache (breedData { breeds = Just breeds })
          fetchTestBreeds = pure (Right testBreeds)

      -- First call should be a miss (not in cache)
      result1 <- fetchWithCache' readCache writeCache fetchTestBreeds cacheRef

      -- Verify result
      result1 `shouldSatisfy` isRight
      case result1 of
        Right (Miss actual) -> actual `shouldEqual` testBreeds
        _ -> fail "Expected a cache miss with correct data"

    it "should return a hit on second call without fetching again" do
      -- Setup cache and test data
      cacheRef <- liftEffect $ initCache ({ breeds: Nothing, images: Map.empty } :: BreedData)
      let testBreeds = [
            { name: "bulldog", subBreeds: [ "french", "english" ] },
            { name: "shepherd", subBreeds: [ "german", "australian" ] }
          ] :: Array BreedFamily

      -- Define reader and writer functions
      let readCache (Cache breedData) = breedData.breeds
          writeCache breeds (Cache breedData) = Cache (breedData { breeds = Just breeds })
          fetchTestBreeds = pure (Right testBreeds)

      -- First call to prime the cache
      _ <- fetchWithCache' readCache writeCache fetchTestBreeds cacheRef

      -- Second call should be a hit (found in cache)
      result2 <- fetchWithCache' readCache writeCache fetchTestBreeds cacheRef

      -- Verify result
      result2 `shouldSatisfy` isRight
      case result2 of
        Right (Hit actual) -> actual `shouldEqual` testBreeds
        _ -> fail "Expected a cache hit with correct data"

    it "should handle fetch errors correctly" do
      -- Setup cache
      cacheRef <- liftEffect $ initCache ({ breeds: Nothing, images: Map.empty } :: BreedData)

      -- Define reader and writer functions with error
      let readCache (Cache breedData) = breedData.breeds
          writeCache breeds (Cache breedData) = Cache (breedData { breeds = Just breeds })
          fetchWithError = pure (Left "Test error") :: Aff (Either String (Array BreedFamily))

      -- Call should return the error
      result <- fetchWithCache' readCache writeCache fetchWithError cacheRef

      -- Verify result
      case result of
        Left err -> err `shouldEqual` "Test error"
        _ -> fail "Expected an error result"

  describe "initCache" do
    it "should initialize a cache with the provided data" do
      let initialData = { breeds: Nothing, images: Map.empty } :: BreedData
      cacheRef <- liftEffect $ initCache initialData
      cache <- liftEffect $ (Ref.read cacheRef)

      -- Verify initial state
      case cache of
        Cache data' -> data' `shouldEqual` initialData