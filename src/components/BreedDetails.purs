module Components.BreedDetails where

import Prelude

import Api (Breed, fetchBreedImages)
import Cache (Cache(..), CacheResult(..), fetchBreedImagesWithCache)
import Components.Pagination as Pagination
import Data.Array (length)
import Data.Either (Either(..))
import Data.Traversable (for_)
import Effect (Effect)
import Effect.Aff (launchAff_)
import Effect.Class (liftEffect)
import Effect.Class.Console (log)
import Effect.Ref (Ref)
import Effect.Ref as Ref
import Web.DOM.Document (Document, createElement)
import Web.DOM.Element (Element, toNode)
import Web.DOM.Node (appendChild, setTextContent, removeChild)

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
displayBreedDetails doc container breed images backButton = do
  -- Create heading with breed name
  heading <- createElement "h2" doc
  setTextContent ("Details for " <> show breed) (toNode heading)
  _ <- appendChild (toNode heading) (toNode container)

  -- Display total image count
  totalCount <- createElement "p" doc
  setTextContent ("Total images: " <> show (length images)) (toNode totalCount)
  _ <- appendChild (toNode totalCount) (toNode container)

  -- Initialize pagination state
  let imagesPerPage = 20
  let initialState = Pagination.initPaginationState imagesPerPage (length images)

  -- Create pagination controls (positioned at the top, after the breed info)
  paginationElements <- Pagination.createPaginationControls doc
  _ <- appendChild (toNode paginationElements.container) (toNode container)

  -- Create a mutable reference to hold pagination state
  stateRef <- Ref.new initialState

  -- Create image container (positioned after pagination controls)
  imageContainer <- createElement "div" doc
  _ <- appendChild (toNode imageContainer) (toNode container)

  -- Function to update display based on pagination state
  let updateDisplay state = do
        -- Clear image container
        clearContainer imageContainer

        -- Get images for current page
        let pageImages = Pagination.getPageItems state images

        -- Display current images
        for_ pageImages \imgUrl -> do
          imgElement <- createElement "img" doc
          setImageSrc imgElement imgUrl
          _ <- appendChild (toNode imgElement) (toNode imageContainer)
          pure unit

        -- Update pagination UI elements
        Pagination.updatePaginationUI paginationElements state

  -- Set up event handlers for pagination buttons
  prevClickHandler <- makeClickHandler doc \_ -> do
    currentState <- Ref.read stateRef
    let newState = Pagination.prevPage currentState
    log $ "Previous clicked - new page: " <> show newState.currentPage
    _ <- Ref.write newState stateRef
    updateDisplay newState

  nextClickHandler <- makeClickHandler doc \_ -> do
    currentState <- Ref.read stateRef
    let newState = Pagination.nextPage currentState
    log $ "Next clicked - new page: " <> show newState.currentPage
    _ <- Ref.write newState stateRef
    updateDisplay newState

  -- Add event listeners to buttons
  _ <- addClickListener paginationElements.prevButton prevClickHandler
  _ <- addClickListener paginationElements.nextButton nextClickHandler

  -- Initialize display with initial state
  updateDisplay initialState

-- Helper functions (implementation depends on Purescript web bindings)
foreign import setImageSrc :: Element -> String -> Effect Unit
foreign import clearContainer :: Element -> Effect Unit
foreign import addClickListener :: Element -> Effect Unit -> Effect Unit
foreign import makeClickHandler :: Document -> (Unit -> Effect Unit) -> Effect (Effect Unit)
