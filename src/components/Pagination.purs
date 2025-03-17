module Components.Pagination
  ( createPaginationControls
  , updatePaginationUI
  ) where

import Prelude
import Effect (Effect)
import PaginationState (PaginationState, isNextDisabled, isPrevDisabled, totalPages)
import Web.DOM.Document (Document, createElement)
import Web.DOM.Element (Element, toNode)
import Web.DOM.Node (appendChild, setTextContent)

-- Type that bundles all pagination UI elements
type PaginationElements =
  { container :: Element
  , prevButton :: Element
  , nextButton :: Element
  , pageInfo :: Element
  }

-- Create pagination controls
createPaginationControls :: Document -> Effect PaginationElements
createPaginationControls doc = do
  -- Create container
  container <- createElement "div" doc
  -- Create buttons and page info
  prevButton <- createElement "button" doc
  setTextContent "Previous" (toNode prevButton)
  nextButton <- createElement "button" doc
  setTextContent "Next" (toNode nextButton)
  pageInfo <- createElement "span" doc
  -- Append elements to container
  _ <- appendChild (toNode prevButton) (toNode container)
  _ <- appendChild (toNode pageInfo) (toNode container)
  _ <- appendChild (toNode nextButton) (toNode container)
  pure { container, prevButton, nextButton, pageInfo }

-- Update pagination UI elements based on current state
updatePaginationUI :: PaginationElements -> PaginationState -> Effect Unit
updatePaginationUI elements state = do
  -- Update page info text
  setTextContent
    ("Page " <> show (state.currentPage + 1) <> " of " <> show (totalPages state))
    (toNode elements.pageInfo)
  -- Enable/disable pagination buttons
  setButtonDisabled elements.prevButton (isPrevDisabled state)
  setButtonDisabled elements.nextButton (isNextDisabled state)

-- Foreign imports (these would be defined in a separate .js file)
foreign import setButtonDisabled :: Element -> Boolean -> Effect Unit

foreign import addClickListener :: Element -> Effect Unit -> Effect Unit
