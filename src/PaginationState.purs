module PaginationState
  ( PaginationState
  , initPaginationState
  , totalPages
  , isPrevDisabled
  , isNextDisabled
  , startIndex
  , endIndex
  , prevPage
  , nextPage
  , getPageItems
  ) where

import Prelude
import Data.Array (slice)
import Data.Int (ceil, toNumber)

type PaginationState
  = { currentPage :: Int
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
  let
    maxPage = totalPages state - 1
  in
    state { currentPage = min maxPage (state.currentPage + 1) }

-- Get the items for the current page
getPageItems :: forall a. PaginationState -> Array a -> Array a
getPageItems state items = slice (startIndex state) (endIndex state) items
