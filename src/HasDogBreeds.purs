module HasDogBreeds
  ( class HasDogBreeds
  , getDogBreeds
  , getBreedImages
  ) where

import Prelude
import Control.Monad.Error.Class (class MonadError)
import Control.Monad.Reader.Trans (ask)
import Data.Lens.At (at)
import AppM (AppM)
import BreedData (Breed, BreedFamily, _breeds, _images)
import Cache (fetchWithCache)
import DogsApi (fetchDogBreeds, fetchBreedImages)
import Effect.Aff (Error)

class (Monad m, MonadError e m) <= HasDogBreeds e m | m -> e where
  getDogBreeds :: m (Array BreedFamily)
  getBreedImages :: Breed -> m (Array String)

instance hasDogBreedsNetwork :: HasDogBreeds Error AppM where
  getDogBreeds = ask >>= fetchWithCache _breeds fetchDogBreeds
  getBreedImages breed = ask >>= fetchWithCache (_images <<< at breed) (fetchBreedImages breed)
