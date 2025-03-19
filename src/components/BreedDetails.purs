module Components.BreedDetails
  ( Output(..)
  , component
  ) where

import Prelude
import Cache (Cache, fetchBreedImagesWithCache)
import Data.Array (length)
import Data.Const (Const)
import Data.Either (Either(..))
import Data.Maybe (Maybe(..))
import DogsApi (Breed)
import Effect.Aff.Class (class MonadAff)
import Effect.Class.Console (log)
import Effect.Ref (Ref)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import PaginationState as PS

-- | Component output message
data Output
  = BackClicked

-- | Component action types
data Action
  = Initialize
  | HandleBackClick
  | NextPage
  | PreviousPage

-- | Component state
type State
  = { breed :: Breed
    , images :: Array String
    , pagination :: PS.PaginationState
    , isLoading :: Boolean
    , error :: Maybe String
    , cache :: Ref Cache
    }

-- | Component definition
component :: forall i m. MonadAff m => Ref Cache -> Breed -> H.Component (Const Void) i Output m
component cache breed =
  H.mkComponent
    { initialState:
        \_ ->
          { breed
          , images: []
          , pagination: PS.initPaginationState 20 0
          , isLoading: true
          , error: Nothing
          , cache
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
    [ renderBackButton
    , if state.isLoading then
        HH.p_ [ HH.text $ "Loading images for " <> show state.breed <> "..." ]
      else case state.error of
        Just err -> HH.p_ [ HH.text $ "Error: " <> err ]
        Nothing ->
          HH.div_
            [ HH.h2_ [ HH.text $ "Details for " <> show state.breed ]
            , HH.p_ [ HH.text $ "Total images: " <> show (length state.images) ]
            , renderPagination state
            , renderImages (PS.getPageItems state.pagination state.images)
            ]
    ]

-- | Render back button
renderBackButton :: forall m. H.ComponentHTML Action () m
renderBackButton =
  HH.button
    [ HE.onClick \_ -> HandleBackClick ]
    [ HH.text "Back to Breed List" ]

-- | Render pagination controls
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

-- | Render images
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
handleAction :: forall m. MonadAff m => Action -> H.HalogenM State Action () Output m Unit
handleAction = case _ of
  Initialize -> do
    state <- H.get
    H.liftEffect $ log $ "Initializing breed details for: " <> show state.breed
    -- Load breed images from the cache
    result <- H.liftAff $ fetchBreedImagesWithCache state.breed state.cache
    case result of
      Left err -> H.modify_ _ { isLoading = false, error = Just err }
      Right images -> do
        H.modify_
          _
            { isLoading = false
            , images = images
            , pagination = PS.initPaginationState 20 (length images)
            , error = Nothing
            }
  HandleBackClick -> do
    H.liftEffect $ log "Going back to breed list"
    H.raise BackClicked
  NextPage -> do
    H.modify_ \state -> state { pagination = PS.nextPage state.pagination }
    state <- H.get
    H.liftEffect $ log $ "Next page - now on page: " <> show (state.pagination.currentPage + 1)
  PreviousPage -> do
    H.modify_ \state -> state { pagination = PS.prevPage state.pagination }
    state <- H.get
    H.liftEffect $ log $ "Previous page - now on page: " <> show (state.pagination.currentPage + 1)
