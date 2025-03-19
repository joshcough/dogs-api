module Components.BreedList (renderBreedList) where

import Prelude

import Cache (Cache, fetchDogBreedsWithCache, getCacheResultValue)
import Data.Array (length)
import Data.Either (Either(..))
import Data.Traversable (for_)
import DogsApi (BreedFamily)
import Effect (Effect)
import Effect.Aff (launchAff_)
import Effect.Class (liftEffect)
import Effect.Ref (Ref)
import Web.DOM.Document (Document, createElement)
import Web.DOM.Element (Element, toNode)
import Web.DOM.Node (appendChild, setTextContent, removeChild)

-- | Type alias for breed selection callback function
type OnBreedSelectFn = String -> Effect Unit

-- | External JavaScript imports
foreign import makeBreedClickable :: Element -> String -> Document -> OnBreedSelectFn -> Effect Unit
foreign import clearContainer :: Element -> Effect Unit

-- | Render the list of dog breeds
renderBreedList :: Document -> Element -> OnBreedSelectFn -> Ref Cache -> Effect Unit
renderBreedList doc container onBreedSelect cacheRef = do
  -- Clear container before adding new content
  clearContainer container

  -- Show loading indicator
  loadingMsg <- createElement "p" doc
  setTextContent "Loading dog breeds..." (toNode loadingMsg)
  _ <- appendChild (toNode loadingMsg) (toNode container)

  -- Fetch breed data
  launchAff_ do
    result <- fetchDogBreedsWithCache cacheRef
    liftEffect do
      -- Remove loading message
      _ <- removeChild (toNode loadingMsg) (toNode container)
      case result of
        -- Handle error case
        Left err -> displayErrorMessage doc container err
        -- Handle success case
        Right cacheRes -> displayBreedList doc container (getCacheResultValue cacheRes) onBreedSelect

-- | Display error message when breeds cannot be loaded
displayErrorMessage :: Document -> Element -> String -> Effect Unit
displayErrorMessage doc container err = do
  errorMsg <- createElement "p" doc
  setTextContent ("Error: " <> err) (toNode errorMsg)
  _ <- appendChild (toNode errorMsg) (toNode container)
  pure unit

-- | Display the breed list once data is successfully loaded
displayBreedList :: Document -> Element -> Array BreedFamily -> OnBreedSelectFn -> Effect Unit
displayBreedList doc container breedFamilies onBreedSelect = do
  -- Create section heading
  heading <- createElement "h2" doc
  setTextContent "Dog Breeds" (toNode heading)
  _ <- appendChild (toNode heading) (toNode container)

  -- Create container for breed items
  breedsContainer <- createElement "div" doc

  -- Add each breed family to the container
  for_ breedFamilies \breedFamily -> do
    breedElement <- createBreedElement doc breedFamily onBreedSelect
    _ <- appendChild (toNode breedElement) (toNode breedsContainer)
    pure unit

  -- Add breeds container to main container
  _ <- appendChild (toNode breedsContainer) (toNode container)
  pure unit

-- | Create an element to display a single breed family
createBreedElement :: Document -> BreedFamily -> OnBreedSelectFn -> Effect Element
createBreedElement doc breedFamily onBreedSelect = do
  -- Create container for the breed family
  container <- createElement "div" doc

  if length breedFamily.subBreeds == 0 then
    -- Handle breed with no sub-breeds
    do
      breedFamilyNameElement <- createElement "h3" doc
      setTextContent breedFamily.name (toNode breedFamilyNameElement)
      _ <- appendChild (toNode breedFamilyNameElement) (toNode container)
      makeBreedClickable breedFamilyNameElement breedFamily.name doc onBreedSelect
  else
    -- Handle breed with sub-breeds
    for_ breedFamily.subBreeds \subBreed -> do
      item <- createElement "h3" doc
      let displayName = breedFamily.name <> " " <> subBreed
      let breedId = breedFamily.name <> "/" <> subBreed

      setTextContent displayName (toNode item)
      _ <- appendChild (toNode item) (toNode container)
      makeBreedClickable item breedId doc onBreedSelect

  pure container