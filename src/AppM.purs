module AppM where

import Prelude

import Control.Monad.Error.Class (class MonadError, class MonadThrow, throwError)
import Control.Monad.Except.Trans (ExceptT, runExceptT)
import Control.Monad.Reader.Trans (class MonadAsk, ReaderT, runReaderT)
import Data.Either (either)
import BreedData (BreedData)
import Effect.Aff (Aff, Error)
import Effect.Aff.Class (class MonadAff)
import Effect.Class (class MonadEffect, liftEffect)
import Effect.Console as Console
import Effect.Now (nowDateTime)
import Effect.Ref (Ref)

type AppEnv = Ref BreedData

newtype AppM a = AppM (ExceptT Error (ReaderT AppEnv Aff) a)

derive newtype instance functorAppM :: Functor AppM
derive newtype instance applyAppM :: Apply AppM
derive newtype instance applicativeAppM :: Applicative AppM
derive newtype instance bindAppM :: Bind AppM
derive newtype instance monadAppM :: Monad AppM
derive newtype instance monadEffectAppM :: MonadEffect AppM
derive newtype instance monadAffAppM :: MonadAff AppM
derive newtype instance monadThrowAppM :: MonadThrow Error AppM
derive newtype instance monadErrorAppM :: MonadError Error AppM
derive newtype instance monadAskAppM :: MonadAsk AppEnv AppM

runAppM :: forall a. Ref BreedData -> AppM a -> Aff a
runAppM cacheRef (AppM m) = 
  runReaderT (runExceptT m) cacheRef >>= either (throwError) pure
