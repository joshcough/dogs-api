module JsonEither where

import Prelude
import Data.Argonaut.Core as JSON
import Data.Either (Either, note)
import Foreign.Object as Object

-- Helper function to extract a field from a JSON object
jsonField :: String -> JSON.Json -> Either String JSON.Json
jsonField fieldName json =
  note ("Missing '" <> fieldName <> "' field") do
    JSON.toObject json >>= Object.lookup fieldName

-- Helper function to convert JSON to an object
jsonObject :: JSON.Json -> Either String (Object.Object JSON.Json)
jsonObject = note "Expected an object" <<< JSON.toObject

-- Helper to convert a JSON value to an array
jsonArray :: JSON.Json -> Either String (Array JSON.Json)
jsonArray = note "Expected an array" <<< JSON.toArray

jsonString :: JSON.Json -> Either String String
jsonString = note "Expected String" <<< JSON.toString
