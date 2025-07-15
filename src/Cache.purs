module Cache
  -- Public API
  ( fetchWithCache
  , getCacheResultValue
  -- For testing only
  , CacheResult(..)
  , fetchWithCache'
  ) where

import Prelude
import Control.Monad.Error.Class (class MonadError)
import Data.Lens (Lens', set, view)
import Data.Maybe (Maybe(..))
import Effect.Aff (Error)
import Effect.Aff.Class (class MonadAff)
import Effect.Class (liftEffect)
import Effect.Ref (Ref)
import Effect.Ref as Ref

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

fetchWithCache ::
  forall m a b.
  MonadAff m =>
  MonadError Error m =>
  Lens' a (Maybe b) ->
  m b ->
  Ref a ->
  m b
fetchWithCache lens fetchAction cacheRef = map getCacheResultValue (fetchWithCache' lens fetchAction cacheRef)

fetchWithCache' ::
  forall m a b.
  MonadAff m =>
  MonadError Error m =>
  Lens' a (Maybe b) -> -- lens to the cached value
  m b -> -- fetch action
  Ref a -> -- cache ref
  m (CacheResult b)
fetchWithCache' lens fetchAction cacheRef = do
  cache <- liftEffect $ Ref.read cacheRef
  case view lens cache of
    Just cached -> pure (Hit cached)
    Nothing -> do
      result <- fetchAction
      liftEffect $ Ref.modify_ (set lens (Just result)) cacheRef
      pure (Miss result)
