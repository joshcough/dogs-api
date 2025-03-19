module Main where

import Prelude
import Components.BreedComponent (renderBreedComponent)
import Effect (Effect)
import Effect.Console (error, log)
import Data.Maybe (Maybe(..))
import Web.HTML (window)
import Web.HTML.Window (document)
import Web.HTML.HTMLDocument (toDocument)
import Web.DOM.ParentNode (QuerySelector(..), querySelector)
import Web.DOM.Document (toParentNode)

main :: Effect Unit
main = do
  htmlDoc <- window >>= document
  mContainer <- querySelector (QuerySelector "#app") (toParentNode (toDocument htmlDoc))
  case mContainer of
    Nothing -> error "Could not find app element"
    Just container -> do
      renderBreedComponent (toDocument htmlDoc) container
      log "Application initialized"
