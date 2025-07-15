module Test.PaginationState where

import Prelude
import Data.Array ((..))
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
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual)

spec :: Spec Unit
spec =
  describe "PaginationState Module" do
    describe "initPaginationState" do
      it "should initialize with correct values" do
        let
          state1 = initPaginationState 10 100
        state1.currentPage `shouldEqual` 0
        state1.itemsPerPage `shouldEqual` 10
        state1.totalItems `shouldEqual` 100
    describe "totalPages" do
      it "should calculate total pages correctly" do
        totalPages (initPaginationState 10 100) `shouldEqual` 10
        totalPages (initPaginationState 10 101) `shouldEqual` 11
        totalPages (initPaginationState 3 10) `shouldEqual` 4
        totalPages (initPaginationState 10 0) `shouldEqual` 0
        totalPages (initPaginationState 10 5) `shouldEqual` 1
    describe "isPrevDisabled" do
      it "should determine if previous button should be disabled" do
        isPrevDisabled (initPaginationState 10 100) `shouldEqual` true
        isPrevDisabled ((initPaginationState 10 100) { currentPage = 1 }) `shouldEqual` false
        isPrevDisabled ((initPaginationState 10 100) { currentPage = 9 }) `shouldEqual` false
    describe "isNextDisabled" do
      it "should determine if next button should be disabled" do
        isNextDisabled (initPaginationState 10 100) `shouldEqual` false
        isNextDisabled ((initPaginationState 10 100) { currentPage = 8 }) `shouldEqual` false
        isNextDisabled ((initPaginationState 10 100) { currentPage = 9 }) `shouldEqual` true
        isNextDisabled (initPaginationState 10 5) `shouldEqual` true
        isNextDisabled (initPaginationState 10 0) `shouldEqual` true
    describe "startIndex" do
      it "should calculate the correct start index" do
        startIndex (initPaginationState 10 100) `shouldEqual` 0
        startIndex ((initPaginationState 10 100) { currentPage = 1 }) `shouldEqual` 10
        startIndex ((initPaginationState 10 100) { currentPage = 9 }) `shouldEqual` 90
        startIndex ((initPaginationState 5 20) { currentPage = 2 }) `shouldEqual` 10
    describe "endIndex" do
      it "should calculate the correct end index" do
        endIndex (initPaginationState 10 100) `shouldEqual` 10
        endIndex ((initPaginationState 10 100) { currentPage = 1 }) `shouldEqual` 20
        endIndex ((initPaginationState 10 100) { currentPage = 9 }) `shouldEqual` 100
        endIndex ((initPaginationState 10 95) { currentPage = 9 }) `shouldEqual` 95
        endIndex ((initPaginationState 5 20) { currentPage = 3 }) `shouldEqual` 20
        endIndex ((initPaginationState 5 13) { currentPage = 2 }) `shouldEqual` 13
    describe "prevPage" do
      it "should navigate to the previous page" do
        let
          state2 = (initPaginationState 10 100) { currentPage = 5 }

          prevState = prevPage state2
        prevState.currentPage `shouldEqual` 4
        (prevPage (initPaginationState 10 100)).currentPage `shouldEqual` 0
        (prevPage ((initPaginationState 10 100) { currentPage = 0 })).currentPage `shouldEqual` 0
    describe "nextPage" do
      it "should navigate to the next page" do
        let
          state3 = (initPaginationState 10 100) { currentPage = 5 }

          nextState = nextPage state3
        nextState.currentPage `shouldEqual` 6
        (nextPage ((initPaginationState 10 100) { currentPage = 9 })).currentPage `shouldEqual` 9
        (nextPage ((initPaginationState 10 5) { currentPage = 0 })).currentPage `shouldEqual` 0
    describe "getPageItems" do
      it "should select items for the first page" do
        let
          items = 0 .. 99

          firstPage = getPageItems (initPaginationState 10 100) items
        firstPage `shouldEqual` (0 .. 9)
      it "should select items for a middle page" do
        let
          items = 0 .. 99

          middlePage = getPageItems ((initPaginationState 10 100) { currentPage = 5 }) items
        middlePage `shouldEqual` (50 .. 59)
      it "should select items for the last page" do
        let
          items = 0 .. 99

          lastPage = getPageItems ((initPaginationState 10 100) { currentPage = 9 }) items
        lastPage `shouldEqual` (90 .. 99)
      it "should handle a partial last page" do
        let
          partialItems = 0 .. 94

          partialLastPage = getPageItems ((initPaginationState 10 95) { currentPage = 9 }) partialItems
        partialLastPage `shouldEqual` (90 .. 94)
      it "should handle edge cases" do
        let
          emptyResult = getPageItems (initPaginationState 10 0) ([] :: Array Int)

          singlePage = getPageItems (initPaginationState 10 5) (0 .. 4)

          oversizedPage = getPageItems (initPaginationState 100 50) (0 .. 49)

          oneItemPerPage = getPageItems ((initPaginationState 1 10) { currentPage = 5 }) (0 .. 9)
        emptyResult `shouldEqual` []
        singlePage `shouldEqual` (0 .. 4)
        oversizedPage `shouldEqual` (0 .. 49)
        oneItemPerPage `shouldEqual` [ 5 ]
