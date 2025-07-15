module BreedData
  ( Breed(..)
  , BreedData
  , BreedFamily
  , _breeds
  , _images
  , emptyBreedData
  ) where

import Prelude

import Data.Lens (Lens')
import Data.Lens.Record (prop)
import Data.Map (Map)
import Data.Map as Map
import Data.Maybe (Maybe(..))
import Type.Proxy (Proxy(..))


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
type BreedData =
  { breeds :: Maybe (Array BreedFamily)
  , images :: Map.Map Breed (Array String)
  }

_breeds :: Lens' BreedData (Maybe (Array BreedFamily))
_breeds = prop (Proxy :: _ "breeds")

_images :: Lens' BreedData (Map Breed (Array String))  
_images = prop (Proxy :: _ "images")

emptyBreedData :: BreedData
emptyBreedData = { breeds: Nothing, images: Map.empty }