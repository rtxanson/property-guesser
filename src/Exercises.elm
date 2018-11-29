module Exercises exposing (Message(..), Model, Question, QuestionType, boop, defaultModel, defaultQuestion, defaultQuestionType, displQ, displQMultiChoice, displayQuestions, genChoices, getQuestionField, init, initialize, update, view)

import Assessor exposing (AssessorRecord, defaultAssessor)
import Elements exposing (..)
import Html exposing (Html)
import Html.Attributes exposing (class, href, src)
import Html.Events exposing (..)
import List.Extra
import Random
import Random.List exposing (shuffle)
import Task
import Tokens
import Url exposing (percentEncode)
import Url.Builder exposing (crossOrigin, string)


mapURLForPoint =
    let
        host =
            "https://api.mapbox.com"

        marker =
            percentEncode "url-https://elections.wedgelive.com/static/img/map_marker.png(-93.2921798,44.9593491)"

        point =
            "-93.2921798,44.9593491,14,0,0"

        auto =
            "auto"

        res =
            "500x500"

        access_token =
            string "access_token" Tokens.mapboxToken

        path =
            [ "styles"
            , "v1"
            , "rtxanson"
            , Tokens.styleId
            , "static"
            , marker
            , point
            , auto
            , res
            ]

        query =
            [ access_token ]
    in
    crossOrigin host path query


mapForPoint =
    div [] [ img [ src mapURLForPoint ] [] ]



-- question set


type alias Model =
    { totalAnswered : Int
    , questionSet : List Question
    , answered : List Question
    , next : Maybe Question
    , initialized : Bool
    , assessorRecords : List AssessorRecord
    , validating : Bool
    }


defaultModel =
    { totalAnswered = 0
    , questionSet = []
    , answered = []
    , next = Nothing
    , initialized = False
    , assessorRecords = []
    , validating = False
    }


type Message
    = ChooseAnswer Question String
    | RandomizeMsg Model
    | RevealHint Question
    | Booped Model
    | GotRandom (List String)
    | GotNewRecords (List AssessorRecord)


type alias Question =
    { questionText : String
    , questionAnswer : String
    , questionHint : String
    , questionType : QuestionType
    , fakeAnswers : List String
    , answered : Bool
    , imagePath : String
    , hintVisible : Bool
    , assessorRecord : AssessorRecord
    }


defaultQuestion =
    { questionText = "Guess the blah blah"
    , questionAnswer = "Foo"
    , questionHint = "Foo"
    , questionType = defaultQuestionType
    , fakeAnswers = [ "foo", "bar", "baz" ]
    , answered = False
    , imagePath = "https://placekitten.com/g/600/600"
    , hintVisible = False
    , assessorRecord = defaultAssessor
    }


type alias QuestionType =
    { typeName : String --
    , questionField : String -- buildingUse, totalValue, etc
    , incorrectsField : String -- buildingUse, totalValue, etc
    , answerType : String -- multichoice, truefalse, guessvalue, etc.
    }


defaultQuestionType =
    multiChoiceBuildingUse


multiChoiceBuildingUse =
    { typeName = "multichoice use"
    , questionField = "buildingUse"
    , incorrectsField = "buildingUse"
    , answerType = "multichoice"
    }


multiChoiceTotalValue =
    { typeName = "multichoice use"
    , questionField = "totalValue"
    , incorrectsField = "totalValue"
    , answerType = "multichoice"
    }



-- create a lazy list of all question types, to be cycled through when
-- converting assessor records to questions


questionTypesCycle =
    [ multiChoiceBuildingUse
    , multiChoiceTotalValue
    ]


questionTextGenerate s =
    case s of
        "buildingUse" ->
            "Guess the building use"

        _ ->
            "Guess the building use"


getQuestionField s =
    case s of
        "buildingUse" ->
            .buildingUse

        "totalValue" ->
            .totalValue

        "numStories" ->
            .numStories

        "totalUnits" ->
            .totalUnits

        _ ->
            .buildingUse


genChoices : Question -> List (Html Message)
genChoices q =
    let
        correctAnswer =
            q.questionAnswer

        -- This is shuffled elsewhere
        allAnswers =
            q.fakeAnswers

        makeAnswer qtext =
            button [ onClick (ChooseAnswer q qtext) ] [ text qtext ]

        answerNodes =
            List.map makeAnswer allAnswers
    in
    answerNodes


displQMultiChoice : Question -> Html Message
displQMultiChoice q =
    btngroup [] (genChoices q)


displayQuestionHint : Question -> Html Message
displayQuestionHint q =
    let
        displClass =
            case q.hintVisible of
                True ->
                    "question-hint hint-visible"

                False ->
                    "question-hint"
    in
    div
        [ class displClass ]
        [ a [ href "#", onClick (RevealHint q), class "hint-note" ] [ text "Need a hint?" ]
        , p [ class "hint-text" ] [ text ("Hint: " ++ q.questionHint) ]
        ]


displQ : Maybe Question -> Html Message
displQ question =
    let
        questionDisplayType qq =
            case qq.questionType.answerType of
                "multichoice" ->
                    displQMultiChoice qq

                _ ->
                    p [] [ text "Unknown question display type." ]
    in
    case question of
        Just q ->
            div []
                [ h4 [] [ text q.assessorRecord.formattedAddress ]
                , img [ src q.imagePath ] []
                , p [] [ text (questionTextGenerate q.questionText) ]
                , questionDisplayType q
                , br [] []
                , br [] []
                , displayQuestionHint q
                , mapForPoint
                ]

        Nothing ->
            div [] [ text "Could not get next question." ]


displayQuestions : Model -> Html Message
displayQuestions qs =
    case qs.next of
        Just q ->
            displQ (Just q)

        Nothing ->
            displQ Nothing


answerIsCorrect : Question -> String -> Question
answerIsCorrect question useranswer =
    if question.questionAnswer == useranswer then
        { question | answered = True }

    else
        question


validateExercise : Model -> Question -> String -> Model
validateExercise qset question useranswer =
    let
        isCorrect =
            answerIsCorrect question useranswer

        newmod =
            case isCorrect.answered of
                False ->
                    qset

                True ->
                    let
                        remaining =
                            List.drop 1 qset.questionSet

                        next =
                            case qset.questionSet of
                                n :: r ->
                                    Just n

                                [] ->
                                    Nothing

                        ans =
                            qset.answered ++ [ question ]
                    in
                    { qset | questionSet = remaining, next = next, answered = ans }
    in
    newmod


randomizeAnswerOrder : Model -> Cmd Message
randomizeAnswerOrder questionset =
    let
        next =
            case questionset.next of
                Just a ->
                    a.fakeAnswers

                Nothing ->
                    []
    in
    Random.generate GotRandom (shuffle next)


boop : Message -> Cmd Message
boop x =
    Task.perform identity (Task.succeed x)


update : Message -> Model -> ( Model, Cmd Message )
update msg model =
    case msg of
        -- Example of touching state that I thought I needed then didn't
        Booped m ->
            ( m
            , Cmd.none
            )

        RevealHint q ->
            let
                newq =
                    { q | hintVisible = True }

                newm =
                    { model | next = Just newq }
            in
            ( newm
            , Cmd.none
            )

        RandomizeMsg m ->
            ( model
            , randomizeAnswerOrder m
            )

        GotRandom randomized ->
            let
                nextQ =
                    case model.next of
                        Just q ->
                            Just { q | fakeAnswers = randomized }

                        Nothing ->
                            Nothing
            in
            ( { model | next = nextQ }
            , Cmd.none
            )

        -- only randomize if current question is correct
        ChooseAnswer question string ->
            let
                validatedm =
                    validateExercise model question string
            in
            ( { validatedm | validating = True }
            , pickAnswers validatedm |> randomizeAnswerOrder
            )

        GotNewRecords recs ->
            let
                questions =
                    makeQuestions recs

                newM =
                    { model | assessorRecords = recs, initialized = True, questionSet = questions }

                initted =
                    initialize newM
            in
            ( initted, pickAnswers initted |> randomizeAnswerOrder )


pickAnswers : Model -> Model
pickAnswers m =
    let
        nn =
            m.next

        next =
            case nn of
                Just newNext ->
                    let
                        -- unique so that the answer doesn't appear
                        -- twice
                        allAns =
                            List.Extra.unique (newNext.fakeAnswers ++ [ newNext.questionAnswer ])

                        excl =
                            List.filter (\x -> x /= newNext.questionAnswer) allAns

                        fakes =
                            List.take 3 excl

                        fa =
                            fakes ++ [ newNext.questionAnswer ]
                    in
                    Just
                        { newNext | fakeAnswers = fa }

                Nothing ->
                    Nothing
    in
    { m | next = next, validating = False }



-- initialize : model -> Model


initialize model =
    let
        questionSet =
            List.drop 1 model.questionSet

        next =
            case model.questionSet of
                n :: nn ->
                    Just n

                [] ->
                    Nothing
    in
    { model | next = next, questionSet = questionSet }


makeQuestions recs =
    let
        assessorRecordToQuestion : AssessorRecord -> Question
        assessorRecordToQuestion ar =
            let
                -- TODO: can we move this stuff to Exercises somehow so
                -- that random question tyeps can be generated?
                qtype =
                    defaultQuestionType

                qFieldSelector =
                    getQuestionField qtype.questionField

                aFieldSelector =
                    getQuestionField qtype.incorrectsField

                others =
                    List.filter (\x -> ar /= x) recs

                fake =
                    List.map aFieldSelector others

                hinttext =
                    qFieldSelector ar

                answer =
                    qFieldSelector ar

                display =
                    fake

                imgpath =
                    "http://localhost:5000/img/" ++ ar.propertyAPN

                question =
                    { defaultQuestion
                        | questionText = qtype.questionField
                        , questionAnswer = answer
                        , questionHint = hinttext
                        , questionType = qtype
                        , fakeAnswers = List.Extra.unique display
                        , imagePath = imgpath
                        , assessorRecord = ar
                    }
            in
            question
    in
    List.map assessorRecordToQuestion recs



-- init : a -> Cmd Message


init state =
    initialize state
        |> pickAnswers
        |> randomizeAnswerOrder


view : Model -> Html Message
view ms =
    let
        vv =
            ms |> displayQuestions
    in
    div [] [ vv ]
