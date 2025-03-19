module Components.BreedComponent (renderBreedComponent) where

import Prelude
import Cache (initCache)
import Components.BreedList (renderBreedList)
import Components.BreedDetails (renderBreedDetails)
import DogsApi (Breed(..))
import Effect (Effect)
import Effect.Class (liftEffect)
import Effect.Console (log)
import Data.Maybe (maybe)
import Data.String (Pattern(..), indexOf, take, drop)
import Web.DOM.Document (Document, createElement)
import Web.DOM.Node (appendChild, setTextContent)
import Web.DOM.Element (Element, toNode)

-- App states
data AppState
  = BreedListState
  | BreedDetailsState Breed

renderBreedComponent :: Document -> Element -> Effect Unit
renderBreedComponent doc container = do
  -- Initialize the cache
  cacheRef <- liftEffect initCache
  -- Create app container
  appContainer <- createElement "div" doc
  -- Create header
  heading <- createElement "h1" doc
  setTextContent "Dog Breeds Explorer" (toNode heading)
  para <- createElement "p" doc
  setTextContent "Browse all dog breeds and their sub-breeds below." (toNode para)
  -- Main content container
  contentContainer <- createElement "div" doc
  -- Append header elements
  let
    containerNode = toNode container
  _ <- appendChild (toNode heading) containerNode
  _ <- appendChild (toNode para) containerNode
  _ <- appendChild (toNode appContainer) containerNode
  _ <- appendChild (toNode contentContainer) (toNode appContainer)
  -- Define state transition functions
  let
    -- Function to handle breed selection
    onBreedSelect :: String -> Effect Unit
    onBreedSelect breedStr = do
      log ("Selected breed: " <> breedStr)
      let
        slashIndex = indexOf (Pattern "/") breedStr

        breed =
          Breed
            { name: maybe breedStr (\ix -> take ix breedStr) slashIndex
            , subBreed: map (\ix -> drop (ix + 1) breedStr) slashIndex
            }
      renderApp (BreedDetailsState breed)

    -- Function to handle going back to breed list
    onBackToList :: Effect Unit
    onBackToList = do
      log "Going back to breed list"
      renderApp BreedListState

    -- Function to render the app based on state
    renderApp :: AppState -> Effect Unit
    renderApp state = case state of
      BreedListState -> renderBreedList doc contentContainer onBreedSelect cacheRef
      BreedDetailsState breed -> renderBreedDetails doc contentContainer onBackToList breed cacheRef
  -- Initial render - start with breed list
  renderApp BreedListState
  log "Application initialized"
