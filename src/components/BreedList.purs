module Components.BreedList where

import Prelude

import Api (BreedFamily)
import Cache (Cache, CacheResult(..), fetchDogBreedsWithCache)
import Data.Array (length)
import Data.Either (Either(..))
import Data.Traversable (for_)
import Effect (Effect)
import Effect.Aff (launchAff_)
import Effect.Class (liftEffect)
import Effect.Ref (Ref)
import Web.DOM.Document (Document, createElement)
import Web.DOM.Element (Element, toNode)
import Web.DOM.Node (appendChild, setTextContent, removeChild)

type OnBreedSelectFn = String -> Effect Unit

-- Create a component to display a single breed family
createBreedElement :: Document -> BreedFamily -> OnBreedSelectFn -> Effect Element
createBreedElement doc breedFamily onBreedSelect = do
  -- Create container for the breed family
  container <- createElement "div" doc

  -- Add breed name as heading (make it clickable)
  nameHeading <- createElement "h3" doc
  setTextContent breedFamily.name (toNode nameHeading)
  makeClickable nameHeading breedFamily.name doc onBreedSelect
  _ <- appendChild (toNode nameHeading) (toNode container)

  -- If there are sub-breeds, display them in a list
  if length breedFamily.subBreeds > 0
    then do
      subBreedsHeading <- createElement "h4" doc
      setTextContent "Sub-breeds:" (toNode subBreedsHeading)
      _ <- appendChild (toNode subBreedsHeading) (toNode container)

      -- Create the list
      list <- createElement "ul" doc

      -- Add each sub-breed as a list item
      for_ breedFamily.subBreeds \subBreed -> do
        item <- createElement "li" doc
        setTextContent subBreed (toNode item)
        -- Make sub-breed clickable with proper naming (breed/subbreed)
        let fullBreedName = breedFamily.name <> "/" <> subBreed
        makeClickable item fullBreedName doc onBreedSelect
        _ <- appendChild (toNode item) (toNode list)
        pure unit

      _ <- appendChild (toNode list) (toNode container)
      pure unit
    else pure unit

  pure container

-- Create a component to render all breeds
renderBreedList :: Document -> Element -> Ref Cache -> OnBreedSelectFn -> Effect Unit
renderBreedList doc container cacheRef onBreedSelect = do
  -- Clear container first
  clearContainer container

  -- Create a loading message
  loadingMsg <- createElement "p" doc
  setTextContent "Loading dog breeds..." (toNode loadingMsg)
  _ <- appendChild (toNode loadingMsg) (toNode container)

  -- Fetch the data and render it
  launchAff_ do
    result <- fetchDogBreedsWithCache cacheRef

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

        Right (Hit breedFamilies) -> do
          displayBreedList doc container breedFamilies onBreedSelect

        Right (Miss breedFamilies) -> do
          displayBreedList doc container breedFamilies onBreedSelect

-- Helper function to display the breed list once data is loaded
displayBreedList :: Document -> Element -> Array BreedFamily -> OnBreedSelectFn -> Effect Unit
displayBreedList doc container breedFamilies onBreedSelect = do
  -- Create a heading
  heading <- createElement "h2" doc
  setTextContent "Dog Breeds" (toNode heading)
  _ <- appendChild (toNode heading) (toNode container)

  -- Create a container for the breeds list
  breedsContainer <- createElement "div" doc

  -- Create and add each breed element
  for_ breedFamilies \breedFamily -> do
    breedElement <- createBreedElement doc breedFamily onBreedSelect
    _ <- appendChild (toNode breedElement) (toNode breedsContainer)
    pure unit

  _ <- appendChild (toNode breedsContainer) (toNode container)
  pure unit

-- Helper functions
foreign import makeClickable :: Element -> String -> Document -> OnBreedSelectFn -> Effect Unit
foreign import clearContainer :: Element -> Effect Unit
