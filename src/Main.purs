module Main where

import Prelude
import Components.BreedComponent (renderBreedComponent)
import Effect (Effect)
import Effect.Console (error)
import Data.Maybe (maybe)
import Web.HTML (window)
import Web.HTML.Window (document)
import Web.HTML.HTMLDocument (toDocument)
import Web.DOM.ParentNode (QuerySelector(..), querySelector)
import Web.DOM.Document (toParentNode)

main :: Effect Unit
main = do
  htmlDoc <- map toDocument $ window >>= document
  mContainer <- querySelector (QuerySelector "#app") (toParentNode htmlDoc)
  maybe (error "Could not find app element") (renderBreedComponent htmlDoc) mContainer
