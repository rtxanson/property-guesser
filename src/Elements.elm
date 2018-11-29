module Elements exposing (a, br, btngroup, button, col, container, div, h3, h4, hr, img, li, p, row, text, ul)

import Html as Html
import Html.Attributes exposing (class)


button aa bb =
    Html.button ([ class "btn btn-primary" ] ++ aa) ([] ++ bb)


row aa bb =
    Html.div ([ class "row" ] ++ aa) ([] ++ bb)


col s aa bb =
    Html.div ([ class ("col-" ++ s) ] ++ aa) ([] ++ bb)


container aa bb =
    Html.div ([ class "container" ] ++ aa) ([] ++ bb)


div =
    Html.div


hr =
    Html.hr


br =
    Html.br


ul aa bb =
    Html.ul ([ class "list-group" ] ++ aa) ([] ++ bb)


btngroup aa bb =
    Html.div ([ class "btn-group-vertical" ] ++ aa) ([] ++ bb)


li =
    Html.li


text =
    Html.text


h3 =
    Html.h3


h4 =
    Html.h4


p =
    Html.p


a =
    Html.a


img =
    Html.img
