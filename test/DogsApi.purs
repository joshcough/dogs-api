module Test.DogsApi where

import Prelude
import BreedData (Breed(..), BreedFamily)
import Data.Array (all, length)
import Data.Maybe (Maybe(..))
import Data.String.Utils (endsWith, startsWith)
import DogsApi (fetchDogBreeds, fetchBreedImages)
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual)

spec :: Spec Unit
spec =
  describe "DogsApi Module" do
    describe "fetchDogBreeds" do
      it "should fetch a non-empty list of dog breeds" do
        breeds <- fetchDogBreeds
        (length breeds >= 100) `shouldEqual` true
    describe "fetchBreedImages" do
      it "should fetch images for a specific breed" do
        let
          bulldogReq = Breed { name: "bulldog", subBreed: Just "french" }
        images <- fetchBreedImages bulldogReq
        (length images >= 5) `shouldEqual` true
        all isValidImageUrl images `shouldEqual` true

getBreedFamilyName :: BreedFamily -> String
getBreedFamilyName breedFamily = breedFamily.name

isValidImageUrl :: String -> Boolean
isValidImageUrl url = startsWith "https://images.dog.ceo/breeds" url && endsWith ".jpg" url
