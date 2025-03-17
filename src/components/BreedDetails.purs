module Components.BreedDetails where

import Prelude

import Api (Breed, fetchBreedImages)
import Cache (Cache(..), CacheResult(..), fetchBreedImagesWithCache)
import Data.Array (length, slice)
import Data.Either (Either(..))
import Data.Int (toNumber, floor)
import Data.Number (ceil)
import Data.Traversable (for_)
import Effect (Effect)
import Effect.Aff (launchAff_)
import Effect.Class (liftEffect)
import Effect.Class.Console (log)
import Effect.Ref as Ref
import Effect.Ref (Ref)
import Web.DOM.Document (Document, createElement)
import Web.DOM.Element (Element, toNode)
import Web.DOM.Node (appendChild, setTextContent, removeChild)

-- Type to represent pagination state with Number for all numeric values
type PaginationState =
  { currentPage :: Number
  , imagesPerPage :: Number
  , totalImages :: Number
  }

-- Initialize pagination state
initPaginationState :: Int -> PaginationState
initPaginationState totalImages =
  { currentPage: 0.0
  , imagesPerPage: 20.0
  , totalImages: toNumber totalImages
  }

-- Create a component to display breed details
renderBreedDetails :: Document -> Element -> Breed -> Ref Cache -> Effect Unit
renderBreedDetails doc container breed cacheRef = do
  -- Clear existing content
  clearContainer container

  -- Create loading message
  loadingMsg <- createElement "p" doc
  setTextContent ("Loading images for " <> show breed <> "...") (toNode loadingMsg)
  _ <- appendChild (toNode loadingMsg) (toNode container)

  -- Create back button (at the top)
  backButton <- createElement "button" doc
  setTextContent "Back to Breed List" (toNode backButton)
  _ <- appendChild (toNode backButton) (toNode container)

  -- Fetch images and render them
  launchAff_ do
    result <- fetchBreedImagesWithCache breed cacheRef

    liftEffect do
      -- Remove loading message
      _ <- removeChild (toNode loadingMsg) (toNode container)

      case result of
        Left err -> do
          -- Display error message
          errorMsg <- createElement "p" doc
          setTextContent ("Error: " <> err) (toNode errorMsg)
          _ <- appendChild (toNode errorMsg) (toNode container)
          pure unit

        Right (Hit images) -> do
          displayBreedDetails doc container breed images backButton

        Right (Miss images) -> do
          displayBreedDetails doc container breed images backButton

-- Helper function to display breed details once images are loaded
displayBreedDetails :: Document -> Element -> Breed -> Array String -> Element -> Effect Unit
displayBreedDetails doc container breed images _backButton = do
  -- Create heading with breed name
  heading <- createElement "h2" doc
  setTextContent ("Details for " <> show breed) (toNode heading)
  _ <- appendChild (toNode heading) (toNode container)

  -- Display total image count
  totalCount <- createElement "p" doc
  setTextContent ("Total images: " <> show (length images)) (toNode totalCount)
  _ <- appendChild (toNode totalCount) (toNode container)

  -- Create image container
  imageContainer <- createElement "div" doc

  -- Create pagination controls
  paginationContainer <- createElement "div" doc
  prevButton <- createElement "button" doc
  setTextContent "Previous" (toNode prevButton)
  nextButton <- createElement "button" doc
  setTextContent "Next" (toNode nextButton)
  pageInfo <- createElement "span" doc

  -- Create a mutable reference to hold pagination state
  stateRef <- Ref.new (initPaginationState (length images))

  -- Create a function to update the display based on pagination state
  let updateDisplay state = do
        -- Clear image container
        clearContainer imageContainer

        -- Calculate page boundaries (convert to Int for array operations)
        let startIndex = floor (state.currentPage * state.imagesPerPage)
        let endIndex = floor (min ((state.currentPage + 1.0) * state.imagesPerPage) state.totalImages)
        let pageImages = slice startIndex endIndex images

        -- Display current images
        for_ pageImages \imgUrl -> do
          imgElement <- createElement "img" doc
          -- Set src attribute using custom function
          setImageSrc imgElement imgUrl
          _ <- appendChild (toNode imgElement) (toNode imageContainer)
          pure unit

        -- Update page info
        setTextContent
          ("Page " <> show (floor (state.currentPage + 1.0)) <> " of " <>
           show (ceil (state.totalImages / state.imagesPerPage)))
          (toNode pageInfo)

        -- Calculate total pages
        let totalPages = ceil (state.totalImages / state.imagesPerPage)
        let lastPageIndex = totalPages - 1.0

        let isPrevButtonDisabled = state.currentPage <= 0.0
        let isNextButtonDisabled = state.currentPage >= lastPageIndex

        log $ "Current page: " <> show state.currentPage
        log $ "totalPages: " <> show totalPages
        log $ "lastPageIndex: " <> show lastPageIndex
        log $ "isPrevButtonDisabled: " <> show isPrevButtonDisabled
        log $ "isNextButtonDisabled: " <> show isNextButtonDisabled

        -- Enable/disable pagination buttons
        setButtonDisabled prevButton isPrevButtonDisabled
        setButtonDisabled nextButton isNextButtonDisabled

  -- Set up event handlers for pagination buttons
  prevClickHandler <- makeClickHandler doc \_ -> do
    currentState <- Ref.read stateRef
    let newState = currentState { currentPage = max 0.0 (currentState.currentPage - 1.0) }
    log $ "Previous clicked - new page: " <> show newState.currentPage
    _ <- Ref.write newState stateRef
    updateDisplay newState

  nextClickHandler <- makeClickHandler doc \_ -> do
    currentState <- Ref.read stateRef
    let totalPages = ceil (currentState.totalImages / currentState.imagesPerPage)
    let maxPage = totalPages - 1.0
    let newState = currentState { currentPage = min maxPage (currentState.currentPage + 1.0) }
    log $ "Next clicked - new page: " <> show newState.currentPage
    _ <- Ref.write newState stateRef
    updateDisplay newState

  -- Add event listeners to buttons
  _ <- addClickListener prevButton prevClickHandler
  _ <- addClickListener nextButton nextClickHandler

  -- Append pagination controls
  _ <- appendChild (toNode prevButton) (toNode paginationContainer)
  _ <- appendChild (toNode pageInfo) (toNode paginationContainer)
  _ <- appendChild (toNode nextButton) (toNode paginationContainer)

  -- Append containers to main container
  _ <- appendChild (toNode paginationContainer) (toNode container)
  _ <- appendChild (toNode imageContainer) (toNode container)

  -- Initialize display with initial state
  initialState <- Ref.read stateRef
  updateDisplay initialState

-- Helper functions (implementation depends on Purescript web bindings)
foreign import setImageSrc :: Element -> String -> Effect Unit
foreign import setButtonDisabled :: Element -> Boolean -> Effect Unit
foreign import addClickListener :: Element -> Effect Unit -> Effect Unit
foreign import clearContainer :: Element -> Effect Unit
foreign import makeClickHandler :: Document -> (Unit -> Effect Unit) -> Effect (Effect Unit)