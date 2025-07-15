module HasDogBreeds
  ( class HasDogBreeds
  , getDogBreeds
  , getBreedImages
  , PureBreedData(..)
  , runPureBreedData
  , CachedBreedData(..)
  , mkCachedBreedData
  ) where

import Prelude
import BreedData (Breed, BreedData, BreedFamily)
import Cache (Cache(..), fetchWithCache)
import Data.Either (Either(..))
import Data.Identity (Identity)
import Data.Maybe (Maybe(..))
import Data.Newtype (class Newtype)
import Data.Map as Map
import Effect.Aff (Aff)
import Effect.Ref (Ref)
import DogsApi (fetchDogBreeds, fetchBreedImages)

-- The revised type class with data source parameter
class Monad m <= HasDogBreeds a m where
  getDogBreeds :: a -> m (Either String (Array BreedFamily))
  getBreedImages :: a -> Breed -> m (Either String (Array String))

-- Pure data source for testing (using a newtype wrapper)
newtype PureBreedData = PureBreedData BreedData

derive instance Newtype PureBreedData _

-- Helper to unwrap the PureBreedData
runPureBreedData :: PureBreedData -> BreedData
runPureBreedData (PureBreedData breedData) = breedData

-- Instance for pure data access with newtype
instance hasDogBreedsPure :: HasDogBreeds PureBreedData Identity where
  getDogBreeds (PureBreedData breedData) = pure case breedData.breeds of
    Just breeds -> Right breeds
    Nothing -> Left "No breeds available in data store"

  getBreedImages (PureBreedData breedData) breed = pure case Map.lookup breed breedData.images of
    Just images -> Right images
    Nothing -> Left "No images available for this breed"

-- Cache data source using a newtype for the Ref
newtype CachedBreedData = CachedBreedData (Ref (Cache BreedData))

derive instance Newtype CachedBreedData _

-- Helper to create a new cached breed data source
mkCachedBreedData :: Ref (Cache BreedData) -> CachedBreedData
mkCachedBreedData = CachedBreedData

-- Instance for cached data access
instance hasDogBreedsCache :: HasDogBreeds CachedBreedData Aff where
  getDogBreeds (CachedBreedData cacheRef) =
    fetchWithCache
      (\(Cache breedData) -> breedData.breeds)
      (\breeds (Cache breedData) -> Cache (breedData { breeds = Just breeds }))
      fetchDogBreeds
      cacheRef

  getBreedImages (CachedBreedData cacheRef) breed =
    fetchWithCache
      (\(Cache breedData) -> Map.lookup breed breedData.images)
      (\images (Cache breedData) -> Cache (breedData { images = Map.insert breed images breedData.images }))
      (fetchBreedImages breed)
      cacheRef