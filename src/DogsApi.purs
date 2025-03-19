module DogsApi
  ( BreedFamily
  , Breed(..)
  , fetchDogBreeds
  , fetchBreedImages
  ) where

import Prelude
import Affjax.Node as AX
import Affjax.ResponseFormat as ResponseFormat
import Data.Argonaut.Core as JSON
import Data.Bifunctor (lmap)
import Data.Either (Either)
import Data.Maybe (Maybe, maybe)
import Data.Traversable (traverse)
import Data.Tuple (Tuple(..))
import Effect.Aff (Aff)
import Foreign.Object as Object
import JsonEither as JE

type BreedFamily = { name :: String, subBreeds :: Array String }

newtype Breed = Breed { name :: String, subBreed :: Maybe String }

derive instance Eq Breed
derive instance Ord Breed
instance Show Breed where
  show (Breed { name, subBreed }) = "Breed " <> show { name, subBreed }

-- Function to fetch all breeds with their sub-breeds
fetchDogBreeds :: Aff (Either String (Array BreedFamily))
fetchDogBreeds = dogsApiRequest "/breeds/list/all" deserializeBreedFamiliesArray
  where
  deserializeBreedFamiliesArray :: JSON.Json -> Either String (Array BreedFamily)
  deserializeBreedFamiliesArray json = do
    breedEntries <- map Object.toUnfoldable $ JE.jsonObject json
    traverse deserializeBreedFamily breedEntries

  deserializeBreedFamily :: Tuple String JSON.Json -> Either String BreedFamily
  deserializeBreedFamily (Tuple name subBreedsJson) = do
    subBreeds <- deserializeSubBreeds subBreedsJson
    pure { name, subBreeds }

  deserializeSubBreeds :: JSON.Json -> Either String (Array String)
  deserializeSubBreeds subBreedsJson = do
    arr <- JE.jsonArray subBreedsJson
    pure $ map (\j -> maybe "" identity (JSON.toString j)) arr

-- Function to fetch images for a specific breed
fetchBreedImages :: Breed -> Aff (Either String (Array String))
fetchBreedImages (Breed { name, subBreed }) = do
  let
    subBreedName = maybe "" (\s -> "/" <> s) subBreed
    path = "/breed/" <> name <> subBreedName <> "/images"
  dogsApiRequest path deserializeBreedImages
  where
  deserializeBreedImages :: JSON.Json -> Either String (Array String)
  deserializeBreedImages imagesJson = JE.jsonArray imagesJson >>= traverse JE.jsonString

-- Construct a request to the dogs api service with the given path
-- Make the request, extract json from the message field, and run the given handler on it.
dogsApiRequest :: forall a. String -> (JSON.Json -> Either String a) -> Aff (Either String a)
dogsApiRequest path handler = do
  let baseUrl = "https://dog.ceo/api"
  response <- map (lmap AX.printError) (AX.get ResponseFormat.json $ baseUrl <> path)
  pure $ response >>= \res -> JE.jsonField "message" res.body >>= handler
