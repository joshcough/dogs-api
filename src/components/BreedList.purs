module Components.BreedList
  ( Output(..)
  , component
  ) where

import Prelude
import BreedData (BreedFamily)
import HasDogBreeds (class HasDogBreeds, getDogBreeds)
import Data.Array (length)
import Data.Const (Const)
import Data.Either (Either(..))
import Data.Maybe (Maybe(..))
import Effect.Class (class MonadEffect)
import Effect.Class.Console (log)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP

-- | Component output type
data Output
  = BreedSelected String

-- | Component action type
data Action
  = Initialize
  | HandleBreedClick String

-- | Component state
type State a
  = { isLoading :: Boolean
    , error :: Maybe String
    , cache :: a
    , breedFamilies :: Maybe (Array BreedFamily)
    }

-- | Component definition
component :: forall a i m. MonadEffect m => HasDogBreeds a m => a -> H.Component (Const Void) i Output m
component cache =
  H.mkComponent
    { initialState:
        \_ ->
          { isLoading: true
          , error: Nothing
          , cache: cache
          , breedFamilies: Nothing
          }
    , render
    , eval:
        H.mkEval
          $ H.defaultEval
              { handleAction = handleAction
              , initialize = Just Initialize
              }
    }

-- | Render function
render :: forall a m. State a -> H.ComponentHTML Action () m
render state =
  HH.div_
    [ if state.isLoading then
        HH.p_ [ HH.text "Loading dog breeds..." ]
      else case state.error of
        Just err -> HH.p_ [ HH.text $ "Error: " <> err ]
        Nothing -> case state.breedFamilies of
          Nothing -> HH.p_ [ HH.text "No breed data available." ]
          Just families ->
            HH.div_
              [ HH.h2_ [ HH.text "Dog Breeds" ]
              , renderBreedsList families
              ]
    ]

-- | Render the breeds list
renderBreedsList :: forall m. Array BreedFamily -> H.ComponentHTML Action () m
renderBreedsList breedFamilies = HH.div_ (map renderBreedFamily breedFamilies)

-- | Render a single breed family
renderBreedFamily :: forall m. BreedFamily -> H.ComponentHTML Action () m
renderBreedFamily breedFamily =
  if length breedFamily.subBreeds == 0 then
    renderBreedItem breedFamily.name breedFamily.name
  else
    HH.div_
      ( map
          ( \subBreed ->
              renderBreedItem
                (breedFamily.name <> " " <> subBreed)
                (breedFamily.name <> "/" <> subBreed)
          )
          breedFamily.subBreeds
      )

-- | Render a single breed item
renderBreedItem :: forall m. String -> String -> H.ComponentHTML Action () m
renderBreedItem displayName breedId =
  HH.h3
    [ HP.style "cursor: pointer; color: #0066cc; text-decoration: underline;"
    , HE.onClick \_ -> HandleBreedClick breedId
    ]
    [ HH.text displayName ]

-- | Action handler
handleAction :: forall a m. MonadEffect m => HasDogBreeds a m => Action -> H.HalogenM (State a) Action () Output m Unit
handleAction = case _ of
  Initialize -> do
    state <- H.get
    H.liftEffect $ log "Initializing breed list component"
    result <- H.lift $ getDogBreeds state.cache
    case result of
      Right bs -> H.modify_ _ { isLoading = false, breedFamilies = Just bs }
      Left err -> do
        H.modify_ _ { isLoading = false, error = Just err }
  HandleBreedClick breedId -> do
    H.liftEffect $ log $ "Breed clicked: " <> breedId
    H.raise $ BreedSelected breedId
