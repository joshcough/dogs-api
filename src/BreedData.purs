module BreedData (
  Breed(..),
  BreedData,
  BreedFamily
) where

import Prelude
import Data.Maybe (Maybe)
import Data.Map as Map

-- | Type representing a breed family with its sub-breeds
type BreedFamily =
  { name :: String
  , subBreeds :: Array String
  }

-- | Type representing a specific dog breed, optionally with a sub-breed
newtype Breed =
  Breed
    { name :: String
    , subBreed :: Maybe String
    }
derive instance Eq Breed
derive instance Ord Breed

instance Show Breed where
  show (Breed { name, subBreed }) = "Breed " <> show { name, subBreed }

-- Updated record type
type BreedData = { breeds :: Maybe (Array BreedFamily)
                 , images :: Map.Map Breed (Array String)
                 }
