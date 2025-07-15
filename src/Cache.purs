module Cache
  -- Public API
  ( Cache(..)
  , fetchWithCache
  , getCacheResultValue
  , initCache
  -- For testing only
  , CacheResult(..)
  , fetchWithCache'
  ) where

import Prelude
import Data.Either (Either(..))
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Aff.Class (class MonadAff)
import Effect.Class (liftEffect)
import Effect.Ref (Ref)
import Effect.Ref as Ref

-- Cache that contains breed families and images for each breed
-- Constructor is not exported so that the cache cannot be directly manipulated
data Cache a
  = Cache a

-- Calls in this module return a CacheResult
-- This is mainly for testing, and regular clients should use getCacheResultValue
data CacheResult a
  = Hit a
  | Miss a

instance showCacheResult :: Show a => Show (CacheResult a) where
  show (Hit a) = "(Hit " <> show a <> ")"
  show (Miss a) = "(Miss " <> show a <> ")"

getCacheResultValue :: forall a. CacheResult a -> a
getCacheResultValue (Hit a) = a

getCacheResultValue (Miss a) = a

-- | Initialize an empty cache
initCache :: forall a. a -> Effect (Ref (Cache a))
initCache a = Ref.new $ Cache a

fetchWithCache ::
  forall m a b.
  MonadAff m =>
  Show a =>
  (Cache a -> Maybe b) ->
  (b -> Cache a -> Cache a) ->
  m (Either String b) ->
  Ref (Cache a) ->
  m (Either String b)
fetchWithCache readCache writeCache fetchNewData cacheRef = map (map getCacheResultValue) (fetchWithCache' readCache writeCache fetchNewData cacheRef)

-- Tries to retrieve a value from the cache
-- If it is present, simply return it.
-- Else run the effect to retrieve it, write it into the cache, and then return it.
fetchWithCache' ::
  forall m a b.
  MonadAff m =>
  Show a =>
  (Cache a -> Maybe b) ->
  (b -> Cache a -> Cache a) ->
  m (Either String b) ->
  Ref (Cache a) ->
  m (Either String (CacheResult b))
fetchWithCache' readCache writeCache fetchNewData cacheRef = do
  cache <- liftEffect $ Ref.read cacheRef
  case readCache cache of
    -- if the value is already in the cache, just return it
    Just a -> pure (Right (Hit a))
    Nothing -> do
      -- if not, go fetch it (which might result in an error)
      result <- fetchNewData
      case result of
        -- if we get a result back, write it into the cache, and return the result
        Right res -> do
          liftEffect (Ref.modify_ (writeCache res) cacheRef)
          -- liftEffect $ log $ "writing data into cache" <> show res
          pure (Right (Miss res))
        -- if we get an error, just return the error
        Left err -> pure $ Left (err)
