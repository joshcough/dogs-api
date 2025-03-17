module ApiCache where

import Prelude

import Api (BreedFamily, Breed, fetchDogBreeds, fetchBreedImages)
import Data.Either (Either(..), either)
import Data.Map as Map
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Aff (Aff)
import Effect.Class (liftEffect)
import Effect.Ref as Ref

-- Define the cache type that only stores successful responses
type Cache =
  { breeds :: Ref.Ref (Maybe (Array BreedFamily))
  , images :: Ref.Ref (Map.Map Breed (Array String))
  }

-- Initialize an empty cache
initCache :: Effect Cache
initCache = do
  breedsRef <- Ref.new Nothing
  imagesRef <- Ref.new Map.empty
  pure { breeds: breedsRef, images: imagesRef }

-- Fetch dog breeds with caching
fetchDogBreedsWithCache :: Cache -> Aff (Either String (Array BreedFamily))
fetchDogBreedsWithCache cache = do
  -- First check if we have cached breeds
  cachedBreeds <- liftEffect $ Ref.read cache.breeds

  case cachedBreeds of
    -- If we have cached data, return it
    Just breeds -> pure (Right breeds)

    -- Otherwise, fetch from API and cache only successful results
    Nothing -> do
      result <- fetchDogBreeds
      case result of
        Right breeds -> liftEffect $ Ref.write (Just breeds) cache.breeds
        Left _ -> pure unit  -- Don't cache errors
      pure result

-- Fetch breed images with caching
fetchBreedImagesWithCache :: Cache -> Breed -> Aff (Either String (Array String))
fetchBreedImagesWithCache cache req = do
  -- Check if we have cached images for this breed
  imagesMap <- liftEffect $ Ref.read cache.images
  let cachedImages = Map.lookup req imagesMap

  case cachedImages of
    -- If we have cached data, return it
    Just images -> pure (Right images)

    -- Otherwise, fetch from API and cache only successful results
    Nothing -> do
      result <- fetchBreedImages req
      case result of
        Right images -> liftEffect $ Ref.modify_ (Map.insert req images) cache.images
        Left _ -> pure unit  -- Don't cache errors
      pure result

-- Add a refresh function for breeds (for manual refresh or when needed)
refreshBreeds :: Cache -> Aff (Either String (Array BreedFamily))
refreshBreeds cache = do
  result <- fetchDogBreeds
  when (isRight result) $ liftEffect $
    Ref.write (either (const Nothing) Just result) cache.breeds
  pure result
  where
    isRight (Right _) = true
    isRight _ = false

-- Add a refresh function for breed images
refreshBreedImages :: Cache -> Breed -> Aff (Either String (Array String))
refreshBreedImages cache req = do
  result <- fetchBreedImages req
  when (isRight result) $ liftEffect $
    Ref.modify_ (Map.insert req (either (const []) identity result)) cache.images
  pure result
  where
    isRight (Right _) = true
    isRight _ = false

-- Clear the breed cache (useful for testing or forcing a refresh)
clearBreedCache :: Cache -> Effect Unit
clearBreedCache cache = Ref.write Nothing cache.breeds

-- Clear the image cache for a specific breed
clearBreedImageCache :: Cache -> Breed -> Effect Unit
clearBreedImageCache cache req =
  Ref.modify_ (Map.delete req) cache.images

-- Clear all image caches
clearAllImageCaches :: Cache -> Effect Unit
clearAllImageCaches cache = Ref.write Map.empty cache.images

-- Clear the entire cache
clearAllCaches :: Cache -> Effect Unit
clearAllCaches cache = do
  clearBreedCache cache
  clearAllImageCaches cache