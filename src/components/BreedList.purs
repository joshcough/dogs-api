module Components.BreedList
  ( Output(..)
  , component
  ) where

import Prelude
import Cache (Cache)
import BreedData (BreedData, BreedFamily)
import Data.Array (length)
import Data.Const (Const)
import Data.Either (Either(..))
import Data.Maybe (Maybe(..))
import Effect.Aff.Class (class MonadAff)
import Effect.Class.Console (log)
import Effect.Ref (Ref)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import HasDogBreeds (getDogBreeds, runCacheBreedM)

-- | Component output type
data Output
  = BreedSelected String

-- | Component action type
data Action
  = Initialize
  | HandleBreedClick String

-- | Component state
type State
  = { isLoading :: Boolean
    , error :: Maybe String
    , cache :: Ref (Cache BreedData)
    , breedFamilies :: Maybe (Array BreedFamily)
    }

-- | Component definition
component :: forall i m. MonadAff m => Ref (Cache BreedData) -> H.Component (Const Void) i Output m
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
render :: forall m. State -> H.ComponentHTML Action () m
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
handleAction :: forall m. MonadAff m => Action -> H.HalogenM State Action () Output m Unit
handleAction = case _ of
  Initialize -> do
    state <- H.get
    H.liftEffect $ log "Initializing breed list component"
    -- Use HasDogBreeds typeclass via CacheBreedM
    result <- H.liftAff $ runCacheBreedM state.cache getDogBreeds
    case result of
      Right bs -> H.modify_ _ { isLoading = false, breedFamilies = Just bs }
      Left err -> do
        H.modify_ _ { isLoading = false, error = Just err }
  HandleBreedClick breedId -> do
    H.liftEffect $ log $ "Breed clicked: " <> breedId
    H.raise $ BreedSelected breedId
