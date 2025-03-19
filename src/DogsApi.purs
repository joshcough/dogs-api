module DogsApi
  ( BreedFamily
  , Breed(..)
  , fetchDogBreeds
  , fetchBreedImages
  ) where

import Prelude
import Affjax (Error, printError)
import Affjax.Node as AX
import Affjax.ResponseFormat as ResponseFormat
import Data.Argonaut.Core as JSON
import Data.Bifunctor (lmap)
import Data.Either (Either)
import Data.Maybe (Maybe(..), maybe)
import Data.Time.Duration (Milliseconds(..))
import Data.Traversable (traverse)
import Data.Tuple (Tuple(..))
import Effect.Aff (Aff)
import Foreign.Object as Object
import JsonEither as JE

type BreedFamily
  = { name :: String, subBreeds :: Array String }

newtype Breed
  = Breed { name :: String, subBreed :: Maybe String }

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
  deserializeSubBreeds json = JE.jsonArray json >>= traverse JE.jsonString

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
  response <- map (lmap prefixNetworkError) (AX.request requestConfig)
  pure $ response >>= extractAndParseMessage
  where
  baseUrl = "https://dog.ceo/api"
  fullUrl = baseUrl <> path

  requestConfig = AX.defaultRequest {
    timeout = Just (Milliseconds 10000.0),
    url = fullUrl,
    responseFormat = ResponseFormat.json
  }

  prefixNetworkError :: Error -> String
  prefixNetworkError err = "Network error for " <> fullUrl <> ": " <> printError err

  extractAndParseMessage :: AX.Response JSON.Json -> Either String a
  extractAndParseMessage r =
    JE.jsonField "message" r.body
      # lmap (\err -> "JSON structure error: " <> err)
      >>= \json -> handler json # lmap (\err -> "Data parsing error: " <> err)
