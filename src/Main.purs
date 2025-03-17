module Main where

import Prelude
import Components.BreedList (renderBreedList)
import Components.BreedDetails (renderBreedDetails)
import Cache (initCacheEff)
import Api (Breed(..))
import Effect (Effect)
import Effect.Console (error, log)
import Data.Maybe (Maybe(..))
import Data.String (Pattern(..), indexOf, take, drop)
import Web.HTML (window)
import Web.HTML.Window (document)
import Web.HTML.HTMLDocument (toDocument)
import Web.DOM.ParentNode (QuerySelector(..), querySelector)
import Web.DOM.Document (Document, toParentNode, createElement)
import Web.DOM.Node (appendChild, setTextContent)
import Web.DOM.Element (toNode, Element)
import Web.DOM.Element as Element

-- App states
data AppState = BreedListState | BreedDetailsState Breed

main :: Effect Unit
main = do
  win <- window
  htmlDoc <- document win
  let doc = toDocument htmlDoc
  mContainer <- querySelector (QuerySelector "#app") (toParentNode doc)

  case mContainer of
    Nothing -> error "Could not find app element"
    Just container -> do
      -- Initialize the cache
      cacheRef <- initCacheEff

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
      let containerNode = toNode container
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
          -- Create a proper Breed record
          let slashIndex = indexOf (Pattern "/") breedStr
              breed = Breed { name: case slashIndex of
                               Just idx -> take idx breedStr
                               Nothing -> breedStr
                      , subBreed: case slashIndex of
                                 Just idx -> Just (drop (idx + 1) breedStr)
                                 Nothing -> Nothing
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
          BreedListState ->
            renderBreedList doc contentContainer cacheRef onBreedSelect

          BreedDetailsState breed -> do
            -- Render breed details
            renderBreedDetails doc contentContainer breed cacheRef

            -- Find back button and add event listener
            mBackButton <- querySelector (QuerySelector "button") (Element.toParentNode contentContainer)
            case mBackButton of
              Nothing -> log "Back button not found"
              Just backButton -> do
                addBackButtonListener backButton onBackToList doc  -- Pass doc as third argument

      -- Initial render - start with breed list
      renderApp BreedListState
      log "Application initialized"

-- Helper function to add event listener to back button
foreign import addBackButtonListener :: Element -> Effect Unit -> Document -> Effect Unit