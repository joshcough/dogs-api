module Test.PaginationState (testPaginationState) where

import Prelude
import Data.Array ((..))
import Effect.Aff (Aff)
import Effect.Class (liftEffect)
import Effect.Class.Console (log)
import PaginationState
  ( initPaginationState
  , totalPages
  , isPrevDisabled
  , isNextDisabled
  , startIndex
  , endIndex
  , prevPage
  , nextPage
  , getPageItems
  )
import Test.Assert (assert)

testPaginationState :: Aff Unit
testPaginationState =
  liftEffect
    $ do
        log "Testing PaginationState module..."
        -- Basic initialization tests
        log "  Testing initPaginationState"
        let
          state1 = initPaginationState 10 100
        assert $ state1.currentPage == 0
        assert $ state1.itemsPerPage == 10
        assert $ state1.totalItems == 100
        -- Testing totalPages calculation
        log "  Testing totalPages"
        assert $ totalPages (initPaginationState 10 100) == 10
        assert $ totalPages (initPaginationState 10 101) == 11
        assert $ totalPages (initPaginationState 3 10) == 4
        assert $ totalPages (initPaginationState 10 0) == 0
        assert $ totalPages (initPaginationState 10 5) == 1
        -- Testing button state calculations
        log "  Testing isPrevDisabled"
        assert $ isPrevDisabled (initPaginationState 10 100) == true
        assert $ isPrevDisabled ((initPaginationState 10 100) { currentPage = 1 }) == false
        assert $ isPrevDisabled ((initPaginationState 10 100) { currentPage = 9 }) == false
        log "  Testing isNextDisabled"
        assert $ isNextDisabled (initPaginationState 10 100) == false
        assert $ isNextDisabled ((initPaginationState 10 100) { currentPage = 8 }) == false
        assert $ isNextDisabled ((initPaginationState 10 100) { currentPage = 9 }) == true
        assert $ isNextDisabled (initPaginationState 10 5) == true
        assert $ isNextDisabled (initPaginationState 10 0) == true
        -- Testing index calculations
        log "  Testing startIndex"
        assert $ startIndex (initPaginationState 10 100) == 0
        assert $ startIndex ((initPaginationState 10 100) { currentPage = 1 }) == 10
        assert $ startIndex ((initPaginationState 10 100) { currentPage = 9 }) == 90
        assert $ startIndex ((initPaginationState 5 20) { currentPage = 2 }) == 10
        log "  Testing endIndex"
        assert $ endIndex (initPaginationState 10 100) == 10
        assert $ endIndex ((initPaginationState 10 100) { currentPage = 1 }) == 20
        assert $ endIndex ((initPaginationState 10 100) { currentPage = 9 }) == 100
        assert $ endIndex ((initPaginationState 10 95) { currentPage = 9 }) == 95
        assert $ endIndex ((initPaginationState 5 20) { currentPage = 3 }) == 20
        assert $ endIndex ((initPaginationState 5 13) { currentPage = 2 }) == 13
        -- Testing navigation functions
        log "  Testing prevPage"
        let
          state2 = (initPaginationState 10 100) { currentPage = 5 }
        let
          prevState = prevPage state2
        assert $ prevState.currentPage == 4
        assert $ (prevPage (initPaginationState 10 100)).currentPage == 0
        assert $ (prevPage ((initPaginationState 10 100) { currentPage = 0 })).currentPage == 0
        log "  Testing nextPage"
        let
          state3 = (initPaginationState 10 100) { currentPage = 5 }
        let
          nextState = nextPage state3
        assert $ nextState.currentPage == 6
        assert $ (nextPage ((initPaginationState 10 100) { currentPage = 9 })).currentPage == 9
        assert $ (nextPage ((initPaginationState 10 5) { currentPage = 0 })).currentPage == 0
        -- Testing page item selection
        log "  Testing getPageItems"
        let
          items = 0 .. 99 -- Array of 100 items
        -- First page
        let
          firstPage = getPageItems (initPaginationState 10 100) items
        assert $ firstPage == (0 .. 9)
        -- Middle page
        let
          middlePage = getPageItems ((initPaginationState 10 100) { currentPage = 5 }) items
        assert $ middlePage == (50 .. 59)
        -- Last page
        let
          lastPage = getPageItems ((initPaginationState 10 100) { currentPage = 9 }) items
        assert $ lastPage == (90 .. 99)
        -- Partial last page
        let
          partialItems = 0 .. 94 -- 95 items
        let
          partialLastPage = getPageItems ((initPaginationState 10 95) { currentPage = 9 }) partialItems
        assert $ partialLastPage == (90 .. 94)
        -- Edge cases
        log "  Testing edge cases"
        -- Empty array
        let
          emptyResult = getPageItems (initPaginationState 10 0) ([] :: Array Int)
        assert $ emptyResult == []
        -- Single page
        let
          singlePage = getPageItems (initPaginationState 10 5) (0 .. 4)
        assert $ singlePage == (0 .. 4)
        -- Oversized page
        let
          oversizedPage = getPageItems (initPaginationState 100 50) (0 .. 49)
        assert $ oversizedPage == (0 .. 49)
        -- Single item per page
        let
          oneItemPerPage = getPageItems ((initPaginationState 1 10) { currentPage = 5 }) (0 .. 9)
        assert $ oneItemPerPage == [ 5 ]
        log "All PaginationState tests passed!"
