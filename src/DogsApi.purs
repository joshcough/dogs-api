module DogsApi
  ( fetchDogBreeds
  , fetchBreedImages
  ) where

import Prelude
import Affjax (printError)
import Affjax.Node as AX
import Affjax.ResponseFormat as ResponseFormat
import Control.Monad.Except (runExcept, throwError)
import Control.Monad.Except.Trans (class MonadError)
import Data.Either (Either(..))
import Data.Generic.Rep (class Generic)
import Data.Maybe (Maybe(..), maybe)
import Data.Time.Duration (Milliseconds(..))
import Data.Tuple (Tuple(..))
import BreedData (Breed(..), BreedFamily)
import Effect.Aff (Error, error)
import Effect.Aff.Class (class MonadAff, liftAff)
import Foreign.Generic (class Decode, decodeJSON, defaultOptions, genericDecode)
import Foreign.Object (Object)
import Foreign.Object as Object

-- | Fetches all dog breeds with their sub-breeds from the API
fetchDogBreeds :: forall m. MonadAff m => MonadError Error m => m (Array BreedFamily)
fetchDogBreeds = toBreedFamilies <$> dogsApiRequest "/breeds/list/all"
  where
  toBreedFamilies (Breeds r) = toBreedFamily <$> Object.toUnfoldable r.message

  toBreedFamily (Tuple name subBreeds) = { name, subBreeds }

fetchBreedImages :: forall m. MonadAff m => MonadError Error m => Breed -> m (Array String)
fetchBreedImages (Breed { name, subBreed }) = do
  let
    -- Handle sub-breed path component if present
    subBreedName = maybe "" (\s -> "/" <> s) subBreed

    -- Construct API path
    path = "/breed/" <> name <> subBreedName <> "/images"
  (\(Images r) -> r.message) <$> dogsApiRequest path

dogsApiRequest :: forall a m. Decode a => MonadAff m => MonadError Error m => String -> m a
dogsApiRequest path = do
  response <- liftAff $ AX.request requestConfig
  case response of
    Left err -> throwError $ error $ printError err
    Right { body } -> case runExcept (decodeJSON body :: _ a) of
      Left decodeErr -> throwError (error $ show decodeErr)
      Right result -> pure result
  where
  baseUrl = "https://dog.ceo/api"

  fullUrl = baseUrl <> path

  requestConfig =
    AX.defaultRequest
      { timeout = Just (Milliseconds 10000.0)
      , url = fullUrl
      , responseFormat = ResponseFormat.string
      }

-- Private data used for deserialization

newtype Breeds
  = Breeds { message :: Object (Array String) }

derive instance genericBreeds :: Generic Breeds _
instance decodeBreeds :: Decode Breeds where
  decode = genericDecode defaultOptions { unwrapSingleConstructors = true }

newtype Images
  = Images { message :: Array String }

derive instance genericImages :: Generic Images _
instance decodeImages :: Decode Images where
  decode = genericDecode defaultOptions { unwrapSingleConstructors = true }
