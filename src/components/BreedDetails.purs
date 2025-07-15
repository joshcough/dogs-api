module Components.BreedDetails
  ( Output(..)
  , component
  ) where

import Prelude

import Control.Monad.Error.Class (try)
import Data.Array (length)
import Data.Const (Const)
import Data.Either (Either(..))
import Data.Maybe (Maybe(..))
import BreedData (Breed)
import HasDogBreeds (class HasDogBreeds, getBreedImages)
import PaginationState as PS
import Effect.Aff (Error, message)
import Effect.Class (class MonadEffect)
import Effect.Class.Console (log)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP

-- | Component output message
data Output = BackClicked

-- | Component action types
data Action
  = Initialize
  | HandleBackClick
  | NextPage
  | PreviousPage

-- | Component state
type State =
  { breed :: Breed
  , images :: Array String
  , pagination :: PS.PaginationState
  , isLoading :: Boolean
  , error :: Maybe String
  }

component
  :: forall i m
   . MonadEffect m
  => HasDogBreeds Error m
  => Breed
  -> H.Component (Const Void) i Output m
component breed =
  H.mkComponent
    { initialState:
        \_ ->
          { breed
          , images: []
          , pagination: PS.initPaginationState 20 0
          , isLoading: true
          , error: Nothing
          }
    , render
    , eval:
        H.mkEval
          $ H.defaultEval
              { handleAction = handleAction
              , initialize = Just Initialize
              }
    }

render :: forall m. State -> H.ComponentHTML Action () m
render state =
  HH.div_
    [ renderBackButton
    , if state.isLoading then
        HH.p_ [ HH.text $ "Loading images for " <> show state.breed <> "..." ]
      else case state.error of
        Just err -> HH.p_ [ HH.text $ "Error: " <> show err ]
        Nothing ->
          HH.div_
            [ HH.h2_ [ HH.text $ "Details for " <> show state.breed ]
            , HH.p_ [ HH.text $ "Total images: " <> show (length state.images) ]
            , renderPagination state
            , renderImages (PS.getPageItems state.pagination state.images)
            ]
    ]

renderBackButton :: forall m. H.ComponentHTML Action () m
renderBackButton =
  HH.button
    [ HE.onClick \_ -> HandleBackClick ]
    [ HH.text "Back to Breed List" ]

renderPagination :: forall m. State -> H.ComponentHTML Action () m
renderPagination state =
  HH.div_
    [ HH.button
        [ HP.disabled (PS.isPrevDisabled state.pagination)
        , HE.onClick \_ -> PreviousPage
        ]
        [ HH.text "Previous" ]
    , HH.span_
        [ HH.text
            $ "Page "
                <> show (state.pagination.currentPage + 1)
                <> " of "
                <> show (PS.totalPages state.pagination)
        ]
    , HH.button
        [ HP.disabled (PS.isNextDisabled state.pagination)
        , HE.onClick \_ -> NextPage
        ]
        [ HH.text "Next" ]
    ]

renderImages :: forall m. Array String -> H.ComponentHTML Action () m
renderImages images =
  HH.div_
    ( map
        ( \imgUrl ->
            HH.img
              [ HP.src imgUrl
              , HP.alt "Dog breed image"
              ]
        )
        images
    )

-- | Action handler
handleAction
  :: forall m
   . HasDogBreeds Error m
  => MonadEffect m
  => Action
  -> H.HalogenM State Action () Output m Unit
handleAction = case _ of
  Initialize -> do
    state <- H.get
    H.liftEffect $ log $ "Initializing breed details for: " <> show state.breed
    result <- H.lift $ try $ getBreedImages state.breed
    case result of
      Left err -> H.modify_ _ { isLoading = false, error = Just $ message err }
      Right images -> do
        H.modify_
          _
            { isLoading = false
            , images = images
            , pagination = PS.initPaginationState 20 (length images)
            , error = Nothing
            }
  HandleBackClick -> H.raise BackClicked
  NextPage -> H.modify_ \state -> state { pagination = PS.nextPage state.pagination }
  PreviousPage -> H.modify_ \state -> state { pagination = PS.prevPage state.pagination }
