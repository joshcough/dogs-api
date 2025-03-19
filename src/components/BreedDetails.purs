module Components.BreedDetails (renderBreedDetails) where

import Prelude

import Cache (Cache, fetchBreedImagesWithCache, getCacheResultValue)
import Data.Array (length)
import Data.Either (Either(..))
import Data.Traversable (for_)
import DogsApi (Breed)
import Effect (Effect)
import Effect.Aff (launchAff_)
import Effect.Class (liftEffect)
import Effect.Class.Console (log)
import Effect.Ref (Ref)
import Effect.Ref as Ref
import PaginationState (PaginationState, isNextDisabled, isPrevDisabled, totalPages)
import PaginationState as PaginationState
import Web.DOM.Document (Document, createElement)
import Web.DOM.Element (Element, toNode)
import Web.DOM.Node (appendChild, setTextContent, removeChild)

-- | Type that bundles all pagination UI elements
type PaginationElements =
  { container :: Element
  , prevButton :: Element
  , nextButton :: Element
  , pageInfo :: Element
  }

-- | Foreign JavaScript imports
foreign import setPaginationButtonDisabled :: Element -> Boolean -> Effect Unit
foreign import addClickListener :: Element -> Effect Unit -> Effect Unit
foreign import setImageSrc :: Element -> String -> Effect Unit
foreign import clearElementContents :: Element -> Effect Unit
foreign import createEventHandler :: Document -> (Unit -> Effect Unit) -> Effect (Effect Unit)
foreign import attachBackButtonListener :: Element -> Effect Unit -> Document -> Effect Unit

-- | Main component renderer for breed details
renderBreedDetails :: Document -> Element -> Effect Unit -> Breed -> Ref Cache -> Effect Unit
renderBreedDetails doc container backButtonOnClick breed cacheRef = do
  -- Clear existing content
  clearElementContents container

  -- Create loading message
  loadingMsg <- createElement "p" doc
  setTextContent ("Loading images for " <> show breed <> "...") (toNode loadingMsg)
  _ <- appendChild (toNode loadingMsg) (toNode container)

  -- Create back button
  backButton <- makeBackButton doc backButtonOnClick
  _ <- appendChild (toNode backButton) (toNode container)

  -- Fetch breed images
  launchAff_ do
    result <- fetchBreedImagesWithCache breed cacheRef
    liftEffect do
      -- Remove loading message
      _ <- removeChild (toNode loadingMsg) (toNode container)

      case result of
        -- Handle error case
        Left err -> displayErrorMessage doc container err
        -- Handle success case
        Right cacheResult -> displayBreedDetails doc container breed (getCacheResultValue cacheResult)

-- | Display error message when images cannot be loaded
displayErrorMessage :: Document -> Element -> String -> Effect Unit
displayErrorMessage doc container err = do
  errorMsg <- createElement "p" doc
  setTextContent ("Error: " <> err) (toNode errorMsg)
  _ <- appendChild (toNode errorMsg) (toNode container)
  pure unit

-- | Create a back button with attached event listener
makeBackButton :: Document -> Effect Unit -> Effect Element
makeBackButton doc backButtonOnClick = do
  backButton <- createElement "button" doc
  setTextContent "Back to Breed List" (toNode backButton)
  attachBackButtonListener backButton backButtonOnClick doc
  pure backButton

-- | Display breed details once images are loaded
displayBreedDetails :: Document -> Element -> Breed -> Array String -> Effect Unit
displayBreedDetails doc container breed images = do
  -- Create heading with breed name
  heading <- createElement "h2" doc
  setTextContent ("Details for " <> show breed) (toNode heading)
  _ <- appendChild (toNode heading) (toNode container)

  -- Display total image count
  totalCount <- createElement "p" doc
  setTextContent ("Total images: " <> show (length images)) (toNode totalCount)
  _ <- appendChild (toNode totalCount) (toNode container)

  -- Initialize pagination
  let imagesPerPage = 20
  let initialState = PaginationState.initPaginationState imagesPerPage (length images)

  -- Create pagination controls
  paginationElements <- createPaginationControls doc
  _ <- appendChild (toNode paginationElements.container) (toNode container)

  -- Create mutable reference for pagination state
  stateRef <- Ref.new initialState

  -- Create image container
  imageContainer <- createElement "div" doc
  _ <- appendChild (toNode imageContainer) (toNode container)

  -- Define display update function
  let
    updateDisplay state = do
      -- Clear image container
      clearElementContents imageContainer

      -- Get images for current page
      let pageImages = PaginationState.getPageItems state images

      -- Display current images
      for_ pageImages \imgUrl -> do
        imgElement <- createElement "img" doc
        setImageSrc imgElement imgUrl
        _ <- appendChild (toNode imgElement) (toNode imageContainer)
        pure unit

      -- Update pagination UI elements
      updatePaginationUI paginationElements state

  -- Set up pagination button handlers
  prevClickHandler <-
    createEventHandler doc \_ -> do
      currentState <- Ref.read stateRef
      let newState = PaginationState.prevPage currentState
      log $ "Previous clicked - new page: " <> show newState.currentPage
      _ <- Ref.write newState stateRef
      updateDisplay newState

  nextClickHandler <-
    createEventHandler doc \_ -> do
      currentState <- Ref.read stateRef
      let newState = PaginationState.nextPage currentState
      log $ "Next clicked - new page: " <> show newState.currentPage
      _ <- Ref.write newState stateRef
      updateDisplay newState

  -- Add event listeners to buttons
  _ <- addClickListener paginationElements.prevButton prevClickHandler
  _ <- addClickListener paginationElements.nextButton nextClickHandler

  -- Initialize display with initial state
  updateDisplay initialState

-- | Create pagination controls UI elements
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

-- | Update pagination UI elements based on current state
updatePaginationUI :: PaginationElements -> PaginationState -> Effect Unit
updatePaginationUI elements state = do
  -- Update page info text
  setTextContent
    ("Page " <> show (state.currentPage + 1) <> " of " <> show (totalPages state))
    (toNode elements.pageInfo)

  -- Enable/disable pagination buttons
  setPaginationButtonDisabled elements.prevButton (isPrevDisabled state)
  setPaginationButtonDisabled elements.nextButton (isNextDisabled state)