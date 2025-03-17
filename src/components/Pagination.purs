module Components.Pagination where

import Prelude

import Data.Int (ceil, toNumber)
import Data.Array (slice)
import Web.DOM.Document (Document, createElement)
import Web.DOM.Element (Element, toNode)
import Web.DOM.Node (appendChild, setTextContent)
import Effect (Effect)

-- Type to represent pagination state with Int for all numeric values
type PaginationState =
  { currentPage :: Int
  , itemsPerPage :: Int
  , totalItems :: Int
  }

-- Initialize pagination state
initPaginationState :: Int -> Int -> PaginationState
initPaginationState itemsPerPage totalItems =
  { currentPage: 0
  , itemsPerPage
  , totalItems
  }

-- Calculate the total number of pages
totalPages :: PaginationState -> Int
totalPages state = ceil (toNumber state.totalItems / toNumber state.itemsPerPage)

-- Is the previous button disabled?
isPrevDisabled :: PaginationState -> Boolean
isPrevDisabled state = state.currentPage <= 0

-- Is the next button disabled?
isNextDisabled :: PaginationState -> Boolean
isNextDisabled state = state.currentPage >= (totalPages state - 1)

-- Calculate the start index for the current page
startIndex :: PaginationState -> Int
startIndex state = state.currentPage * state.itemsPerPage

-- Calculate the end index for the current page
endIndex :: PaginationState -> Int
endIndex state = min ((state.currentPage + 1) * state.itemsPerPage) state.totalItems

-- Move to the previous page
prevPage :: PaginationState -> PaginationState
prevPage state = state { currentPage = max 0 (state.currentPage - 1) }

-- Move to the next page
nextPage :: PaginationState -> PaginationState
nextPage state =
  let maxPage = totalPages state - 1
  in state { currentPage = min maxPage (state.currentPage + 1) }

-- Get the items for the current page
getPageItems :: forall a. PaginationState -> Array a -> Array a
getPageItems state items = slice (startIndex state) (endIndex state) items

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

