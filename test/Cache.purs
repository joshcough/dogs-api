module Test.Cache where

import Prelude

import Control.Monad.Error.Class (try)
import Data.Either (Either(..))
import BreedData (BreedFamily, _breeds, emptyBreedData)
import Cache (CacheResult(..), fetchWithCache')
import Effect.Aff (error, message, throwError)
import Effect.Class (liftEffect)
import Effect.Ref as Ref
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (fail, shouldEqual)

spec :: Spec Unit
spec = describe "Cache Module" do

  let testBreeds = [
        { name: "bulldog", subBreeds: [ "french", "english" ] },
        { name: "shepherd", subBreeds: [ "german", "australian" ] }
      ] :: Array BreedFamily

  describe "fetchWithCache'" do
    it "should return a miss on first call and fetch data" do
      cacheRef <- liftEffect $ Ref.new emptyBreedData
      result1 <- fetchWithCache' _breeds (pure testBreeds) cacheRef
      -- First call should be a miss (not in cache)
      case result1 of
        Miss actual -> actual `shouldEqual` testBreeds
        _ -> fail "Expected a cache miss with correct data"

    it "should return a hit on second call without fetching again" do
      cacheRef <- liftEffect $ Ref.new emptyBreedData
      -- First call to prime the cache
      _ <- fetchWithCache' _breeds (pure testBreeds) cacheRef
      -- Second call should be a hit (found in cache)
      result2 <- fetchWithCache' _breeds (pure testBreeds) cacheRef
      case result2 of
        Hit actual -> actual `shouldEqual` testBreeds
        _ -> fail "Expected a cache hit with correct data"

    it "should handle fetch errors correctly" do
      cacheRef <- liftEffect $ Ref.new emptyBreedData
      -- Call should return the error
      result <- try $ fetchWithCache' _breeds (throwError $ error "Test error") cacheRef
      case result of
        Left err -> message err `shouldEqual` "Test error"
        _ -> fail "Expected an error result"
