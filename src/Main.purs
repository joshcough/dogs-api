module Main where

import Prelude
import Effect (Effect)
import Effect.Console (error, log)
import Data.Maybe (Maybe(..))
import Web.HTML (window)
import Web.HTML.Window (document)
import Web.HTML.HTMLDocument (toDocument)
import Web.DOM.ParentNode (QuerySelector(..), querySelector)
import Web.DOM.Document (toParentNode, createElement)
import Web.DOM.Node (appendChild, setTextContent)
import Web.DOM.Element (toNode)
import BreedComponent (renderBreedList)

main :: Effect Unit
main = do
  doc <- window >>= \w -> map toDocument (document w)
  mContainer <- querySelector (QuerySelector "#app") (toParentNode doc)
  case mContainer of
    Nothing -> error "Could not find app element"
    Just container -> do
      heading <- map toNode (createElement "h1" doc)
      setTextContent "Dog Breeds Explorer" heading
      para <- map toNode (createElement "p" doc)
      setTextContent "Browse all dog breeds and their sub-breeds below." para
      breedsContainer <- createElement "div" doc
      let containerNode = toNode container
      _ <- appendChild heading containerNode
      _ <- appendChild para containerNode
      _ <- appendChild (toNode breedsContainer) containerNode
      renderBreedList doc breedsContainer
      log "Application initialized"