module ApiCache where

import Prelude

import Api (BreedFamily, Breed, fetchDogBreeds, fetchBreedImages)
import Data.Either (Either(..))
import Data.Map as Map
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Aff (Aff)
import Effect.Class (liftEffect)
import Effect.Ref (Ref)
import Effect.Ref as Ref

-- Define the cache type that only stores successful responses
type Cache =
  { breeds :: Maybe (Array BreedFamily)
  , images :: Map.Map Breed (Array String)
  }

-- Initialize an empty cache
initCache :: Effect (Ref Cache)
initCache = Ref.new { breeds: Nothing, images: Map.empty }

-- Fetch dog breeds with caching
fetchDogBreedsWithCache :: Ref Cache -> Aff (Either String (Array BreedFamily))
fetchDogBreedsWithCache =
  fetchWithCache
    (\c -> c.breeds)
    (\breeds cache -> cache {breeds = Just breeds})
    fetchDogBreeds

-- Fetch breed images with caching
fetchBreedImagesWithCache :: Breed -> Ref Cache -> Aff (Either String (Array String))
fetchBreedImagesWithCache breed =
  fetchWithCache
    (\c -> Map.lookup breed c.images)
    (\images cache -> cache {images = Map.insert breed images cache.images})
    (fetchBreedImages breed)

-- A function for working with the cache.
fetchWithCache :: forall a .
  (Cache -> Maybe a) ->
  (a -> Cache -> Cache) ->
  Aff (Either String a) ->
  Ref Cache ->
  Aff (Either String a)
fetchWithCache readCache writeCache fetchNewData cacheRef = do
  cache <- liftEffect $ Ref.read cacheRef
  case readCache cache of
    -- if the value is already in the cache, just return it
    Just a -> pure (Right a)
    Nothing -> do
      -- if not, go fetch it (which might result in an error)
      result <- fetchNewData
      case result of
        -- if we get a result back, write it into the cache, and return the result
        Right res -> do
          liftEffect (Ref.modify_ (writeCache res) cacheRef)
          pure (Right res)
        -- if we get an error, just return the error
        Left err -> pure $ Left (err)
