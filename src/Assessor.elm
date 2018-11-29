module Assessor exposing (AssessorRecord, Message(..), Model, decodeAssessor, decodeAssessors, defaultAssessor, getJson, init, update)

import Http
import Json.Decode as Decode exposing (Value, null, nullable, oneOf)
import Json.Decode.Pipeline exposing (hardcoded, optional, optionalAt, required, requiredAt)
import List.Extra exposing (unique)
import Task


type Message
    = GotAssessor (Result Http.Error (List AssessorRecord))


type alias AssessorRecord =
    { propertyAPN : String
    , buildingUse : String
    , totalValue : String
    , totalUnits : String
    , numStories : String
    , formattedAddress : String
    }


defaultAssessor =
    { propertyAPN = "asdf"
    , buildingUse = "asdf"
    , totalValue = "asdf"
    , totalUnits = "asdf"
    , numStories = "asdf"
    , formattedAddress = "asdf"
    }


type alias Model =
    { assessorRecs : List AssessorRecord
    }


initialModel =
    { assessorRecs = []
    }


decodeAssessor : Decode.Decoder AssessorRecord
decodeAssessor =
    Decode.succeed AssessorRecord
        |> required "APN" Decode.string
        |> required "BUILDINGUSE" Decode.string
        |> required "TOTALVALUE" Decode.string
        |> required "TOTAL_UNITS" Decode.string
        |> required "NUM_STORIES" Decode.string
        |> required "FORMATTED_ADDRESS" Decode.string


decodeAssessors =
    Decode.list decodeAssessor


getJson =
    Http.request
        { method = "GET"
        , headers = []
        , url = "http://localhost:5000/"
        , body = Http.emptyBody
        , expect = Http.expectJson decodeAssessors
        , withCredentials = False
        , timeout = Nothing
        }


boop : Message -> Cmd Message
boop x =
    Task.perform identity (Task.succeed x)


update : Message -> Model -> ( Model, Cmd Message )
update msg model =
    case msg of
        GotAssessor res ->
            case res of
                Ok assessorrecs ->
                    ( { assessorRecs = assessorrecs }
                    , Cmd.none
                    )

                Err _ ->
                    ( { assessorRecs = [] }
                    , Cmd.none
                    )


init : ( Model, Cmd Message )
init =
    ( initialModel, Http.send GotAssessor getJson )
