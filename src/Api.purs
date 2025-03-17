module Api where

import Prelude
import Affjax.Node as AX
import Affjax.ResponseFormat as ResponseFormat
import Data.Array (sort)
import Data.Bifunctor (lmap)
import Data.Either (Either(..))
import Data.Maybe (Maybe(..))
import Data.Argonaut.Core as JSON
import Effect.Aff (Aff)
import Effect.Class.Console (log)
import Foreign.Object as Object

-- Define the URL for the dog API
baseUrl :: String
baseUrl = "https://dog.ceo/api"

-- Function to fetch the list of dog breeds
fetchDogBreeds :: Aff (Either String (Array String))
fetchDogBreeds = do
  log $ "Sending request to " <> baseUrl <> "/breeds/list/all"
  response <- map (lmap AX.printError) (AX.get ResponseFormat.json (baseUrl <> "/breeds/list/all"))
  case response of
    Left err -> pure $ Left $ "Error fetching dog breeds: " <> err
    Right res -> do
      log $ "Response received successfully"

      -- Extract the message field which contains breeds
      let json = res.body
          messageField = JSON.toObject json >>= \obj -> Object.lookup "message" obj

      case messageField of
        Nothing -> pure $ Left "Missing 'message' field in response"
        Just msgJson ->
          case JSON.toObject msgJson of
            Nothing -> pure $ Left "'message' field is not an object"
            Just breedObj -> do
              log $ "msgJson: " <> JSON.stringify msgJson
              pure $ Right $ sort $ Object.keys breedObj

-- Function to fetch images for a specific breed
fetchBreedImages :: String -> Aff (Either String (Array String))
fetchBreedImages breed = do
  let url = baseUrl <> "/breed/" <> breed <> "/images"
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