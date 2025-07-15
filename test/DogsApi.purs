module Test.DogsApi where

import Prelude
import BreedData (Breed(..))
import Data.Array (length)
import Data.Maybe (Maybe(..))
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
