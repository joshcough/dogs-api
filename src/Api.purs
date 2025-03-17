module Api where

import Prelude

import Affjax.Node as AX
import Affjax.ResponseFormat as ResponseFormat
import Data.Argonaut.Core as JSON
import Data.Bifunctor (lmap)
import Data.Either (Either, note)
import Data.Maybe (Maybe, maybe)
import Data.Traversable (sequence, traverse)
import Data.Tuple (Tuple(..))
import Effect.Aff (Aff)
import Foreign.Object as Object

baseUrl :: String
baseUrl = "https://dog.ceo/api"

type BreedFamily = { name :: String, subBreeds :: Array String }

-- Parse sub-breeds from a JSON value
parseSubBreeds :: JSON.Json -> Either String (Array String)
parseSubBreeds json = do
  arr <- jsonArray json
  pure $ map (\j -> maybe "" identity (JSON.toString j)) arr

-- Function to fetch all breeds with their sub-breeds
fetchDogBreeds :: Aff (Either String (Array BreedFamily))
fetchDogBreeds = dogsApiRequest "/breeds/list/all" $ \res -> do
  breedObj <- jsonObject res
  let breedEntries = Object.toUnfoldable breedObj :: Array (Tuple String JSON.Json)
      breeds = map (\(Tuple name subBreedsJson) -> do
        subBreeds <- parseSubBreeds subBreedsJson
        pure { name, subBreeds }) breedEntries
  sequence breeds

newtype Breed = Breed { name :: String, subBreed :: Maybe String }

derive instance Eq Breed
derive instance Ord Breed

instance Show Breed where
  show (Breed { name, subBreed }) =
    "Breed " <> show { name, subBreed }

mkBreedImageReq :: String -> Maybe String -> Breed
mkBreedImageReq name subBreed = Breed { name, subBreed }

-- Function to fetch images for a specific breed
fetchBreedImages :: Breed -> Aff (Either String (Array String))
fetchBreedImages (Breed { name, subBreed }) = do
  let subBreedName = maybe "" (\s -> "/" <> s) subBreed
  let path = "/breed/" <> name <> subBreedName <> "/images"
  dogsApiRequest path $ \res -> jsonArray res >>= traverse jsonString

-- Construct a request to the dogs api service with the given path
dogsApiRequest :: forall a. String -> (JSON.Json -> Either String a) -> Aff (Either String a)
dogsApiRequest path handler = do
  let url = baseUrl <> path
  response <- map (lmap AX.printError) (AX.get ResponseFormat.json url)
  pure $ response >>= \res -> jsonField "message" res.body >>= handler

-- Helper function to extract a field from a JSON object
jsonField :: String -> JSON.Json -> Either String JSON.Json
jsonField fieldName json = note ("Missing '" <> fieldName <> "' field") do
  JSON.toObject json >>= Object.lookup fieldName

-- Helper function to convert JSON to an object
jsonObject :: JSON.Json -> Either String (Object.Object JSON.Json)
jsonObject = note "Expected an object" <<< JSON.toObject

-- Helper to convert a JSON value to an array
jsonArray :: JSON.Json -> Either String (Array JSON.Json)
jsonArray = note "Expected an array" <<< JSON.toArray

jsonString :: JSON.Json -> Either String String
jsonString = note "Expected String" <<< JSON.toString