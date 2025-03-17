module Api where

import Prelude

import Affjax.Node as AX
import Affjax.ResponseFormat as ResponseFormat
import Data.Argonaut.Core as JSON
import Data.Bifunctor (lmap)
import Data.Either (Either(..), note)
import Data.Maybe (Maybe(..), maybe)
import Data.Traversable (sequence)
import Data.Tuple (Tuple(..))
import Effect.Aff (Aff)
import Effect.Class.Console (log)
import Foreign.Object as Object

-- Define the URL for the dog API
baseUrl :: String
baseUrl = "https://dog.ceo/api"

type Breed = { name :: String, subBreeds :: Array String }

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

-- Parse sub-breeds from a JSON value
parseSubBreeds :: JSON.Json -> Either String (Array String)
parseSubBreeds json = do
  arr <- jsonArray json
  pure $ map (\j -> maybe "" identity (JSON.toString j)) arr

-- Function to fetch all breeds with their sub-breeds
fetchDogBreeds :: Aff (Either String (Array Breed))
fetchDogBreeds = do
  let url = baseUrl <> "/breeds/list/all"
  response <- map (lmap (\err -> "Error fetching dog breeds: " <> AX.printError err))
                 (AX.get ResponseFormat.json url)
  case response of
    Left err -> pure $ Left err
    Right res -> do
      let result = do
            messageJson <- jsonField "message" res.body
            breedObj <- jsonObject messageJson
            let breedEntries = Object.toUnfoldable breedObj :: Array (Tuple String JSON.Json)
                breeds = map (\(Tuple name subBreedsJson) -> do
                  subBreeds <- parseSubBreeds subBreedsJson
                  pure { name, subBreeds }) breedEntries
            sequence breeds
      pure result

-- Function to fetch images for a specific breed
fetchBreedImages :: String -> Aff (Either String (Array String))
fetchBreedImages breedName = do
  let url = baseUrl <> "/breed/" <> breedName <> "/images"
  log $ "Sending request to " <> url
  response <- AX.get ResponseFormat.json url
  case response of
    Left err -> pure $ Left $ "Error fetching breed images: " <> AX.printError err
    Right res -> do
      log $ "Response received successfully"

      -- Extract the message field which contains images
      let json = res.body
          messageField = JSON.toObject json >>= \obj -> Object.lookup "message" obj

      case messageField of
        Nothing -> pure $ Left "Missing 'message' field in response"
        Just msgJson ->
          case JSON.toArray msgJson of
            Nothing -> pure $ Left "'message' field is not an array"
            Just imageArray ->
              pure $ Right $ map (\j -> case JSON.toString j of
                                         Just s -> s
                                         Nothing -> "") imageArray