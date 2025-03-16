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
import Web.DOM.Element as Element

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
      setTextContent "Hello from PureScript!" (toNode heading)

      -- Create paragraph element
      para <- createElement "p" docAsDoc
      setTextContent "This is a basic web page rendered with PureScript" (toNode para)

      -- Add elements to container
      _ <- appendChild (toNode heading) (toNode container)
      _ <- appendChild (toNode para) (toNode container)

      log "HTML elements added to the page"