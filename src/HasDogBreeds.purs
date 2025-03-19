module HasDogBreeds
  ( class HasDogBreeds
  , getDogBreeds
  , getBreedImages
  , PureBreedM
  , runPureBreedM
  , CacheBreedM
  , runCacheBreedM
  ) where

import Prelude
import BreedData (Breed, BreedData, BreedFamily)
import Cache (Cache(..), fetchWithCache)
import Control.Monad.Reader (ReaderT, ask, runReaderT)
import Data.Either (Either(..))
import Data.Identity (Identity)
import Data.Maybe (Maybe(..))
import Data.Newtype (unwrap)
import DogsApi (fetchDogBreeds, fetchBreedImages)
import Data.Map as Map
import Effect.Aff (Aff)
import Effect.Aff.Class (liftAff)
import Effect.Ref (Ref)

class
  Monad m <= HasDogBreeds m where
  getDogBreeds :: m (Either String (Array BreedFamily))
  getBreedImages :: Breed -> m (Either String (Array String))

-- Pure implementation (for testing)
newtype PureBreedM a
  = PureBreedM (ReaderT BreedData Identity a)

-- Derive necessary instances
derive newtype instance functorPureBreedM :: Functor PureBreedM

derive newtype instance applyPureBreedM :: Apply PureBreedM

derive newtype instance applicativePureBreedM :: Applicative PureBreedM

derive newtype instance bindPureBreedM :: Bind PureBreedM

derive newtype instance monadPureBreedM :: Monad PureBreedM

-- Helper to run the pure monad
runPureBreedM :: forall a. BreedData -> PureBreedM a -> a
runPureBreedM breedData (PureBreedM m) = unwrap (runReaderT m breedData)

-- Instance for pure data access
instance hasDogBreedsPure :: HasDogBreeds PureBreedM where
  getDogBreeds =
    PureBreedM do
      breedData <- ask
      pure case breedData.breeds of
        Just breeds -> Right breeds
        Nothing -> Left "No breeds available in data store"
  getBreedImages breed =
    PureBreedM do
      breedData <- ask
      pure case Map.lookup breed breedData.images of
        Just images -> Right images
        Nothing -> Left "No images available for this breed"

-- Cache implementation uses a Ref to BreedData
-- Cache implementation uses a Ref to Cache BreedData
newtype CacheBreedM a
  = CacheBreedM (ReaderT (Ref (Cache BreedData)) Aff a)

derive newtype instance functorCacheBreedM :: Functor CacheBreedM

derive newtype instance applyCacheBreedM :: Apply CacheBreedM

derive newtype instance applicativeCacheBreedM :: Applicative CacheBreedM

derive newtype instance bindCacheBreedM :: Bind CacheBreedM

derive newtype instance monadCacheBreedM :: Monad CacheBreedM

-- Helper to run the cache monad
runCacheBreedM :: forall a. Ref (Cache BreedData) -> CacheBreedM a -> Aff a
runCacheBreedM cacheRef (CacheBreedM m) = runReaderT m cacheRef

-- Instance for cached data access
instance hasDogBreedsCache :: HasDogBreeds CacheBreedM where
  getDogBreeds =
    CacheBreedM do
      cacheRef <- ask
      liftAff
        $ fetchWithCache
            (\(Cache breedData) -> breedData.breeds)
            (\breeds (Cache breedData) -> Cache (breedData { breeds = Just breeds }))
            fetchDogBreeds
            cacheRef
  getBreedImages breed =
    CacheBreedM do
      cacheRef <- ask
      liftAff
        $ fetchWithCache
            (\(Cache breedData) -> Map.lookup breed breedData.images)
            (\images (Cache breedData) -> Cache (breedData { images = Map.insert breed images breedData.images }))
            (fetchBreedImages breed)
            cacheRef
