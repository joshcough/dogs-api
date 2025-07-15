module DogsApi
  ( fetchDogBreeds
  , fetchBreedImages
  ) where

import Prelude
import Affjax (Error, printError)
import Affjax.Node as AX
import Affjax.ResponseFormat as ResponseFormat
import BreedData (Breed(..), BreedFamily)
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

-- | Fetches all dog breeds with their sub-breeds from the API
fetchDogBreeds :: Aff (Either String (Array BreedFamily))
fetchDogBreeds = dogsApiRequest "/breeds/list/all" deserializeBreedFamiliesArray
  where
  -- Convert JSON response to an array of breed families
  deserializeBreedFamiliesArray :: JSON.Json -> Either String (Array BreedFamily)
  deserializeBreedFamiliesArray json = do
    breedEntries <- map Object.toUnfoldable $ JE.jsonObject json
    traverse deserializeBreedFamily breedEntries

  -- Convert a single breed entry to a BreedFamily
  deserializeBreedFamily :: Tuple String JSON.Json -> Either String BreedFamily
  deserializeBreedFamily (Tuple name subBreedsJson) = do
    subBreeds <- deserializeSubBreeds subBreedsJson
    pure { name, subBreeds }

  -- Parse the sub-breeds array from JSON
  deserializeSubBreeds :: JSON.Json -> Either String (Array String)
  deserializeSubBreeds json = JE.jsonArray json >>= traverse JE.jsonString

-- | Fetches images for a specific breed from the API
fetchBreedImages :: Breed -> Aff (Either String (Array String))
fetchBreedImages (Breed { name, subBreed }) = do
  let
    -- Handle sub-breed path component if present
    subBreedName = maybe "" (\s -> "/" <> s) subBreed

    -- Construct API path
    path = "/breed/" <> name <> subBreedName <> "/images"
  dogsApiRequest path deserializeBreedImages
  where
  -- Parse the image URLs array from JSON
  deserializeBreedImages :: JSON.Json -> Either String (Array String)
  deserializeBreedImages imagesJson = JE.jsonArray imagesJson >>= traverse JE.jsonString

-- | Helper function to make requests to the Dog API
-- |
-- | - Constructs the full URL
-- | - Makes the request with proper timeout
-- | - Extracts the "message" field from response
-- | - Runs the provided handler on the extracted JSON
dogsApiRequest :: forall a. String -> (JSON.Json -> Either String a) -> Aff (Either String a)
dogsApiRequest path handler = do
  response <- map (lmap prefixNetworkError) (AX.request requestConfig)
  pure $ response >>= extractAndParseMessage
  where
  baseUrl = "https://dog.ceo/api"

  fullUrl = baseUrl <> path

  requestConfig =
    AX.defaultRequest
      { timeout = Just (Milliseconds 10000.0)
      , url = fullUrl
      , responseFormat = ResponseFormat.json
      }

  -- Add context to network errors
  prefixNetworkError :: Error -> String
  prefixNetworkError err = "Network error for " <> fullUrl <> ": " <> printError err

  -- Extract message field and handle parsing
  extractAndParseMessage :: AX.Response JSON.Json -> Either String a
  extractAndParseMessage r =
    JE.jsonField "message" r.body
      # lmap (\err -> "JSON structure error: " <> err)
      >>= \json -> handler json # lmap (\err -> "Data parsing error: " <> err)
