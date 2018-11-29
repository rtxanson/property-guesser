module Main exposing (Model, Msg(..), init, main, update, view)

import Assessor exposing (..)
import Browser
import Exercises exposing (..)
import Html exposing (Html, div, h1, text)
import Html.Events exposing (..)
import Http



---- MODEL ----


type alias StateModel =
    { nextQuestions : List Question
    , assessorRecs : List AssessorRecord
    , questionType : String
    , exercise : Exercises.Model
    }


initialState =
    { nextQuestions = []
    , assessorRecs = []
    , questionType = "NULL"
    , exercise = Exercises.defaultModel
    }


type Model
    = Home StateModel
    | Exercise Exercises.Model



---- UPDATE ----


type Msg
    = NoOp
    | AssessorMsg Assessor.Message
    | ExercisesMsg Exercises.Message


update : Msg -> StateModel -> ( StateModel, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model
            , Cmd.none
            )

        -- Assessor module
        AssessorMsg subMsg ->
            let
                ( newM, newMsg ) =
                    Assessor.update subMsg { assessorRecs = [] }

                mod =
                    { model
                        | assessorRecs = newM.assessorRecs
                        , questionType = "NULL"
                    }
            in
            -- TODO: hand off to Exercises.GotNewRecords recs
            ( mod, Cmd.map ExercisesMsg (Exercises.boop (GotNewRecords newM.assessorRecs)) )

        -- ( mod, Cmd.map AssessorMsg newMsg )
        -- Exercises module
        ExercisesMsg subMsg ->
            let
                ( newM, newMsg ) =
                    Exercises.update subMsg model.exercise
            in
            ( { model | exercise = newM }, Cmd.map ExercisesMsg newMsg )



---- VIEW ----


view : StateModel -> Html Msg
view model =
    let
        -- wrap the message from module in (Html Msg) with local union type
        initialView =
            Html.map ExercisesMsg (Exercises.view model.exercise)
    in
    div []
        [ h1 [] [ text "Property Guesser" ]
        , initialView
        ]



---- PROGRAM ----


init : ( StateModel, Cmd Msg )
init =
    let
        ( a, b ) =
            Assessor.init

        start =
            Cmd.map AssessorMsg b
    in
    ( initialState, start )


main : Program () StateModel Msg
main =
    Browser.element
        { view = view
        , init = \_ -> init
        , update = update
        , subscriptions = always Sub.none
        }
