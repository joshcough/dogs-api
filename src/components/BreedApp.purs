module Components.BreedApp (component) where

import Prelude
import Cache (Cache)
import Components.BreedDetails as BreedDetails
import Components.BreedList as BreedList
import Data.Const (Const)
import Data.Maybe (Maybe(..))
import Data.String (Pattern(..), indexOf, take, drop)
import DogsApi (Breed(..))
import Effect.Aff.Class (class MonadAff)
import Effect.Class.Console (log)
import Effect.Ref (Ref)
import Halogen as H
import Halogen.HTML as HH
import Type.Proxy (Proxy(..))

-- | Component state
type State
  = { currentView :: View
    , cache :: Ref Cache
    }

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
component :: forall q i o m. MonadAff m => Ref Cache -> H.Component q i o m
component cache =
  H.mkComponent
    { initialState:
        \_ ->
          { currentView: BreedListState
          , cache: cache
          }
    , render
    , eval:
        H.mkEval
          $ H.defaultEval
              { handleAction = handleAction
              }
    }

-- | Slot proxies
_breedList = Proxy :: Proxy "breedList"

_breedDetails = Proxy :: Proxy "breedDetails"

-- | Render function
render :: forall m. MonadAff m => State -> H.ComponentHTML Action Slots m
render state =
  HH.div_
    [ HH.h1_ [ HH.text "Dog Breeds Explorer" ]
    , renderContent state
    ]

-- | Render the appropriate content based on state
renderContent :: forall m. MonadAff m => State -> H.ComponentHTML Action Slots m
renderContent state = case state.currentView of
  BreedListState -> HH.slot _breedList unit (BreedList.component state.cache) unit handleBreedList
  BreedDetailsState breed -> HH.slot _breedDetails unit (BreedDetails.component state.cache breed) unit handleBreedDetails

-- | Handle events from BreedList component
handleBreedList :: BreedList.Output -> Action
handleBreedList (BreedList.BreedSelected breedStr) = SelectBreed breedStr

-- | Handle events from BreedDetails component
handleBreedDetails :: BreedDetails.Output -> Action
handleBreedDetails BreedDetails.BackClicked = BackToBreedList

-- | Action handler
handleAction :: forall m o. MonadAff m => Action -> H.HalogenM State Action Slots o m Unit
handleAction = case _ of
  SelectBreed breedStr -> do
    H.liftEffect $ log $ "Selected breed: " <> breedStr
    -- Parse the breed string (same logic as original)
    let
      slashIndex = indexOf (Pattern "/") breedStr

      breed =
        Breed
          { name:
              case slashIndex of
                Nothing -> breedStr
                Just ix -> take ix breedStr
          , subBreed: map (\ix -> drop (ix + 1) breedStr) slashIndex
          }
    H.modify_ _ { currentView = BreedDetailsState breed }
  BackToBreedList -> do
    H.liftEffect $ log "Going back to breed list"
    H.modify_ _ { currentView = BreedListState }
