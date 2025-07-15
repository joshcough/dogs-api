module Test.DogsApi where

import Prelude

import BreedData (BreedFamily, Breed(..))
import Data.Array (elem, length, null, all)
import Data.Either (Either(..), isRight)
import Data.Maybe (Maybe(..), isJust)
import Data.String (indexOf)
import Data.String.Pattern (Pattern(..))
import DogsApi (fetchDogBreeds, fetchBreedImages)
import Effect.Aff (Aff)
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldSatisfy, shouldEqual, fail)

spec :: Spec Unit
spec = describe "DogsApi Module" do
  describe "fetchDogBreeds" do
    it "should fetch a non-empty list of dog breeds" do
      result <- fetchDogBreeds
      result `shouldSatisfy` isRight

      case result of
        Left err -> fail $ "Unexpected error: " <> err
        Right breeds -> do
          (not $ null breeds) `shouldEqual` true
          (length breeds >= 100) `shouldEqual` true

  describe "fetchBreedImages" do
    it "should fetch images for a specific breed" do
      let bulldogReq = Breed { name: "bulldog", subBreed: Just "french" }
      result <- fetchBreedImages bulldogReq
      result `shouldSatisfy` isRight

      case result of
        Left err -> fail $ "Unexpected error: " <> err
        Right images -> do
          (not $ null images) `shouldEqual` true
          (length images >= 5) `shouldEqual` true

-- Helper functions
getBreedFamilyName :: BreedFamily -> String
getBreedFamilyName breedFamily = breedFamily.name

isValidImageUrl :: String -> Boolean
isValidImageUrl url = startsWith "https://images.dog.ceo" url && contains "jpg" url

startsWith :: String -> String -> Boolean
startsWith prefix str = indexOf (Pattern prefix) str == Just 0

contains :: String -> String -> Boolean
contains substr str = isJust (indexOf (Pattern substr) str)