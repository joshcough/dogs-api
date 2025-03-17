module Main where

import Prelude
import Effect (Effect)
import Effect.Console (log)
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
  w <- window
  doc <- document w
  let docAsDoc = toDocument doc
  let parentNode = toParentNode docAsDoc

  mContainer <- querySelector (QuerySelector "#app") parentNode
  case mContainer of
    Nothing -> log "Could not find app element"
    Just container -> do
      -- Create heading element
      heading <- createElement "h1" docAsDoc
      setTextContent "Dog Breeds Explorer" (toNode heading)

      -- Create intro paragraph
      para <- createElement "p" docAsDoc
      setTextContent "Browse all dog breeds and their sub-breeds below." (toNode para)

      -- Create a container for the breeds
      breedsContainer <- createElement "div" docAsDoc

      -- Add elements to container
      _ <- appendChild (toNode heading) (toNode container)
      _ <- appendChild (toNode para) (toNode container)
      _ <- appendChild (toNode breedsContainer) (toNode container)

      -- Render the breeds list in the container
      renderBreedList docAsDoc breedsContainer

      log "Application initialized"