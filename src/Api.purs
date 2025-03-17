module Api
  ( baseUrl
  , BreedFamily
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
import Data.Traversable (sequence, traverse)
import Data.Tuple (Tuple(..))
import Effect.Aff (Aff)
import Foreign.Object as Object
import JsonEither as JE

baseUrl :: String
baseUrl = "https://dog.ceo/api"

type BreedFamily = { name :: String, subBreeds :: Array String }

newtype Breed = Breed { name :: String, subBreed :: Maybe String }

derive instance Eq Breed
derive instance Ord Breed
instance Show Breed where
  show (Breed { name, subBreed }) =
    "Breed " <> show { name, subBreed }

-- Function to fetch all breeds with their sub-breeds
fetchDogBreeds :: Aff (Either String (Array BreedFamily))
fetchDogBreeds =
  dogsApiRequest "/breeds/list/all"
    $ \res -> do
        breedObj <- JE.jsonObject res
        let
          breedEntries = Object.toUnfoldable breedObj :: Array (Tuple String JSON.Json)

          breeds =
            map
              ( \(Tuple name subBreedsJson) -> do
                  subBreeds <- do
                    arr <- JE.jsonArray subBreedsJson
                    pure $ map (\j -> maybe "" identity (JSON.toString j)) arr
                  pure { name, subBreeds }
              )
              breedEntries
        sequence breeds

-- Function to fetch images for a specific breed
fetchBreedImages :: Breed -> Aff (Either String (Array String))
fetchBreedImages (Breed { name, subBreed }) = do
  let
    subBreedName = maybe "" (\s -> "/" <> s) subBreed
  let
    path = "/breed/" <> name <> subBreedName <> "/images"
  dogsApiRequest path $ \res -> JE.jsonArray res >>= traverse JE.jsonString

-- Construct a request to the dogs api service with the given path
dogsApiRequest :: forall a. String -> (JSON.Json -> Either String a) -> Aff (Either String a)
dogsApiRequest path handler = do
  let
    url = baseUrl <> path
  response <- map (lmap AX.printError) (AX.get ResponseFormat.json url)
  pure $ response >>= \res -> JE.jsonField "message" res.body >>= handler
