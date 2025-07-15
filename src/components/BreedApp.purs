module Components.BreedApp (component) where

import Prelude
import Data.Const (Const)
import Data.Maybe (maybe)
import Data.String (Pattern(..), indexOf, take, drop)
import BreedData (Breed(..))
import Components.BreedDetails as BreedDetails
import Components.BreedList as BreedList
import HasDogBreeds (class HasDogBreeds)
import Effect.Aff (Error)
import Effect.Class (class MonadEffect)
import Effect.Class.Console (log)
import Halogen as H
import Halogen.HTML as HH
import Type.Proxy (Proxy(..))

-- | Component state
type State
  = { currentView :: View }

-- | View state enum - matches the original AppState
data View
  = BreedListState
  | BreedDetailsState Breed

-- | Component actions
data Action
  = SelectBreed String
  | BackToBreedList

-- | Child component slots
type Slots
  = ( breedList :: H.Slot (Const Void) BreedList.Output Unit
    , breedDetails :: H.Slot (Const Void) BreedDetails.Output Unit
    )

-- | Component definition
component ::
  forall q i o m.
  MonadEffect m =>
  HasDogBreeds Error m =>
  H.Component q i o m
component =
  H.mkComponent
    { initialState: \_ -> { currentView: BreedListState }
    , render
    , eval: H.mkEval $ H.defaultEval { handleAction = handleAction }
    }

-- | Slot proxies
_breedList = Proxy :: Proxy "breedList"

_breedDetails = Proxy :: Proxy "breedDetails"

-- | Render function
render ::
  forall m.
  MonadEffect m =>
  HasDogBreeds Error m =>
  State ->
  H.ComponentHTML Action Slots m
render state =
  HH.div_
    [ HH.h1_ [ HH.text "Dog Breeds Explorer" ]
    , renderContent state
    ]

-- | Render the appropriate content based on state
renderContent ::
  forall m.
  MonadEffect m =>
  HasDogBreeds Error m =>
  State ->
  H.ComponentHTML Action Slots m
renderContent state = case state.currentView of
  BreedListState -> HH.slot _breedList unit BreedList.component unit handleBreedList
  BreedDetailsState breed -> HH.slot _breedDetails unit (BreedDetails.component breed) unit handleBreedDetails

-- | Handle events from BreedList.purs component
handleBreedList :: BreedList.Output -> Action
handleBreedList (BreedList.BreedSelected breedStr) = SelectBreed breedStr

-- | Handle events from BreedDetails component
handleBreedDetails :: BreedDetails.Output -> Action
handleBreedDetails BreedDetails.BackClicked = BackToBreedList

-- | Action handler
handleAction ::
  forall m o.
  MonadEffect m =>
  HasDogBreeds Error m =>
  Action ->
  H.HalogenM State Action Slots o m Unit
handleAction = case _ of
  SelectBreed breedStr -> do
    H.liftEffect $ log $ "Selected breed: " <> breedStr
    let
      slashIndex = indexOf (Pattern "/") breedStr

      breed =
        Breed
          { name: maybe breedStr (\ix -> take ix breedStr) slashIndex
          , subBreed: map (\ix -> drop (ix + 1) breedStr) slashIndex
          }
    H.modify_ _ { currentView = BreedDetailsState breed }
  BackToBreedList -> do
    H.liftEffect $ log "Going back to breed list"
    H.modify_ _ { currentView = BreedListState }
