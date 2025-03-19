module Components.BreedComponent (renderBreedComponent) where

import Prelude

import Cache (initCache)
import Components.BreedDetails (renderBreedDetails)
import Components.BreedList (renderBreedList)
import Data.Maybe (maybe)
import Data.String (Pattern(..), indexOf, take, drop)
import DogsApi (Breed(..))
import Effect (Effect)
import Effect.Class (liftEffect)
import Effect.Console (log)
import Web.DOM.Document (Document, createElement)
import Web.DOM.Element (Element, toNode)
import Web.DOM.Node (appendChild, setTextContent)

-- | Application state representation
data AppState
  = BreedListState
  | BreedDetailsState Breed

-- | Main component renderer
renderBreedComponent :: Document -> Element -> Effect Unit
renderBreedComponent doc container = do
  -- Initialize the cache
  cacheRef <- liftEffect initCache

  -- Create DOM elements
  appContainer <- createElement "div" doc
  heading <- createElement "h1" doc
  contentContainer <- createElement "div" doc

  -- Set content
  setTextContent "Dog Breeds Explorer" (toNode heading)

  -- Build DOM structure
  let containerNode = toNode container
  _ <- appendChild (toNode heading) containerNode
  _ <- appendChild (toNode appContainer) containerNode
  _ <- appendChild (toNode contentContainer) (toNode appContainer)

  -- Set up state transitions
  let
    -- Handle breed selection
    onBreedSelect :: String -> Effect Unit
    onBreedSelect breedStr = do
      log ("Selected breed: " <> breedStr)
      renderApp (BreedDetailsState (parseBreed breedStr))

    -- Handle back navigation
    onBackToList :: Effect Unit
    onBackToList = do
      log "Going back to breed list"
      renderApp BreedListState

    -- Parse breed string into Breed data structure
    parseBreed :: String -> Breed
    parseBreed breedStr =
      let
        slashIndex = indexOf (Pattern "/") breedStr
      in
        Breed
          { name: maybe breedStr (\ix -> take ix breedStr) slashIndex
          , subBreed: map (\ix -> drop (ix + 1) breedStr) slashIndex
          }

    -- Render application based on current state
    renderApp :: AppState -> Effect Unit
    renderApp = case _ of
      BreedListState ->
        renderBreedList doc contentContainer onBreedSelect cacheRef
      BreedDetailsState breed ->
        renderBreedDetails doc contentContainer onBackToList breed cacheRef

  -- Initial render with breed list
  renderApp BreedListState
  log "Application initialized"