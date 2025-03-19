module Components.BreedList (renderBreedList) where

import Prelude
import Cache (Cache, fetchDogBreedsWithCache, getCacheResultValue)
import DogsApi (BreedFamily)
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

type OnBreedSelectFn
  = String -> Effect Unit

-- Create a component to render all breeds
renderBreedList :: Document -> Element -> OnBreedSelectFn -> Ref Cache -> Effect Unit
renderBreedList doc container onBreedSelect cacheRef = do
  -- Clear container first
  clearContainer container
  -- Create a loading message
  loadingMsg <- createElement "p" doc
  setTextContent "Loading dog breeds..." (toNode loadingMsg)
  _ <- appendChild (toNode loadingMsg) (toNode container)
  launchAff_ do
    -- Load the breeds (or just get it from the cache)
    result <- fetchDogBreedsWithCache cacheRef
    liftEffect do
      -- We finished loading, so remove loading message
      _ <- removeChild (toNode loadingMsg) (toNode container)
      case result of
        -- Error loading, so display error message
        Left err -> displayErrorMessage doc container err
        -- Finally we display the breed list now that its loaded
        Right cacheRes -> displayBreedList doc container (getCacheResultValue cacheRes) onBreedSelect

displayErrorMessage :: Document -> Element -> String -> Effect Unit
displayErrorMessage doc container err = do
  errorMsg <- createElement "p" doc
  setTextContent ("Error: " <> err) (toNode errorMsg)
  appendChild (toNode errorMsg) (toNode container)

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

-- Create a component to display a single breed family
createBreedElement :: Document -> BreedFamily -> OnBreedSelectFn -> Effect Element
createBreedElement doc breedFamily onBreedSelect = do
  -- Create container for the breed family
  container <- createElement "div" doc
  -- Add breed name as heading
  breedFamilyNameElement <- createElement "h3" doc
  setTextContent breedFamily.name (toNode breedFamilyNameElement)
  _ <- appendChild (toNode breedFamilyNameElement) (toNode container)
  -- If there are no sub breeds, then make the breed family name clickable.
  if length breedFamily.subBreeds == 0 then
    makeBreedClickable breedFamilyNameElement breedFamily.name doc onBreedSelect
  -- else there are sub-breeds, display them in a list and make each sub-breed clickable.
  else do
    subBreedsHeading <- createElement "h4" doc
    setTextContent "Sub-breeds:" (toNode subBreedsHeading)
    _ <- appendChild (toNode subBreedsHeading) (toNode container)
    list <- createElement "ul" doc
    for_ breedFamily.subBreeds \subBreed -> do
      item <- createElement "li" doc
      setTextContent subBreed (toNode item)
      let
        fullBreedName = breedFamily.name <> "/" <> subBreed
      makeBreedClickable item fullBreedName doc onBreedSelect
      _ <- appendChild (toNode item) (toNode list)
      pure unit
    _ <- appendChild (toNode list) (toNode container)
    pure unit
  pure container

foreign import makeBreedClickable :: Element -> String -> Document -> OnBreedSelectFn -> Effect Unit

foreign import clearContainer :: Element -> Effect Unit
