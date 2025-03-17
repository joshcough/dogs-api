module BreedComponent where

import Prelude

import Api (Breed, fetchDogBreeds)
import Data.Array (length)
import Data.Either (Either(..))
import Data.Traversable (for_)
import Effect (Effect)
import Effect.Aff (launchAff_)
import Effect.Class (liftEffect)
import Web.DOM.Document (Document, createElement)
import Web.DOM.Element (Element, toNode)
import Web.DOM.Node (appendChild, setTextContent, removeChild)

-- Create a component to display a single breed
createBreedElement :: Document -> Breed -> Effect Element
createBreedElement doc breed = do
  -- Create container for the breed
  container <- createElement "div" doc

  -- Add breed name as heading
  nameHeading <- createElement "h3" doc
  setTextContent breed.name (toNode nameHeading)
  _ <- appendChild (toNode nameHeading) (toNode container)

  -- If there are sub-breeds, display them in a list
  if length breed.subBreeds > 0
    then do
      subBreedsHeading <- createElement "h4" doc
      setTextContent "Sub-breeds:" (toNode subBreedsHeading)
      _ <- appendChild (toNode subBreedsHeading) (toNode container)

      -- Create the list
      list <- createElement "ul" doc

      -- Add each sub-breed as a list item
      for_ breed.subBreeds \subBreed -> do
        item <- createElement "li" doc
        setTextContent subBreed (toNode item)
        _ <- appendChild (toNode item) (toNode list)
        pure unit

      _ <- appendChild (toNode list) (toNode container)
      pure unit
    else pure unit

  pure container

-- Create a component to render all breeds
renderBreedList :: Document -> Element -> Effect Unit
renderBreedList doc container = do
  -- Create a loading message
  loadingMsg <- createElement "p" doc
  setTextContent "Loading dog breeds..." (toNode loadingMsg)
  _ <- appendChild (toNode loadingMsg) (toNode container)

  -- Fetch the data and render it
  launchAff_ do
    result <- fetchDogBreeds

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

        Right breeds -> do
          -- Create a heading
          heading <- createElement "h2" doc
          setTextContent "Dog Breeds" (toNode heading)
          _ <- appendChild (toNode heading) (toNode container)

          -- Create a container for the breeds list
          breedsContainer <- createElement "div" doc

          -- Create and add each breed element
          for_ breeds \breed -> do
            breedElement <- createBreedElement doc breed
            _ <- appendChild (toNode breedElement) (toNode breedsContainer)
            pure unit

          _ <- appendChild (toNode breedsContainer) (toNode container)
          pure unit