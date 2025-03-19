module JsonEither
  ( jsonField
  , jsonObject
  , jsonArray
  , jsonString
  ) where

import Prelude
import Data.Argonaut.Core as JSON
import Data.Either (Either, note)
import Foreign.Object as Object

-- | Extract a field from a JSON object, or fail if the field is missing
jsonField :: String -> JSON.Json -> Either String JSON.Json
jsonField fieldName json =
  note ("Missing '" <> fieldName <> "' field") do
    JSON.toObject json >>= Object.lookup fieldName

-- | Convert JSON to an Object, or fail if the JSON is not an Object
jsonObject :: JSON.Json -> Either String (Object.Object JSON.Json)
jsonObject = note "Expected an object" <<< JSON.toObject

-- | Convert JSON to an Array, or fail if the JSON is not an Array
jsonArray :: JSON.Json -> Either String (Array JSON.Json)
jsonArray = note "Expected an array" <<< JSON.toArray

-- | Convert JSON to a String, or fail if the JSON is not a String
jsonString :: JSON.Json -> Either String String
jsonString = note "Expected String" <<< JSON.toString
