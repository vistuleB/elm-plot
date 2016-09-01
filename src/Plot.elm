module Plot exposing (..)

import Html exposing (Html, button, div, text)
import Svg exposing (g)
import Svg.Attributes exposing (height, width, style, d)
import String

import Helpers exposing (viewSvgLine)
import Debug


type alias SerieConfig data =
    { color : String
    , areaColor : String
    , toCoords : data -> List (Float, Float)
    }


type alias PlotConfig data =
  { name : String
  , height : Int
  , width : Int
  , series : List (SerieConfig data)
  }


viewPlot : PlotConfig data -> List data -> Html msg
viewPlot config data =
  let
    axisProps' = axisProps config.series data
    toSvgCoords' = toSvgCoords config axisProps' data
    { lowestX, lowestY, highestX, highestY } = axisProps'
  in
    Svg.svg
      [ Svg.Attributes.height (toString config.height)
      , Svg.Attributes.width (toString config.width)
      , style "padding: 50px;"
      ]
      [ Svg.g [] [ viewLine toSvgCoords' (lowestX, 0, highestX, 0) ]
      , Svg.g [] [ viewLine toSvgCoords' (0, lowestY, 0, highestY) ]
      , Svg.g [] (List.map2 (viewSeries toSvgCoords') config.series data)
      ]


toSvgCoords : PlotConfig data -> AxisProps -> List data -> (Float, Float) -> (String, String)
toSvgCoords config { lowestX, lowestY, highestX, highestY } data  =
  let
    totalX =  abs highestX + abs lowestX
    originX = (toFloat config.width) * (abs lowestX / totalX)
    totalY =  (abs highestY + abs lowestY)
    originY = (toFloat config.height) * (abs highestY / totalY)
    deltaX = (toFloat config.width) / totalX
    deltaY = (toFloat config.height) / totalY

    toSvgX = (\x -> toString (originX + x * deltaX))
    toSvgY = (\y -> toString (originY + y * deltaY * -1))
  in
    (\(x, y) -> (toSvgX x, toSvgY y))


type alias AxisProps =
  { highestX : Float
  , highestY : Float
  , lowestX : Float
  , lowestY : Float
  }

{- Retrive range of axis from data -}
axisProps : List (SerieConfig data) -> List data -> AxisProps
axisProps series data =
  let
    allCoords = List.concat (List.map2 .toCoords series data)
    allX = List.map fst allCoords
    allY = List.map snd allCoords
    highest = (\values -> Maybe.withDefault 1 (List.maximum values))
    lowest = (\values -> min 0 (Maybe.withDefault 0 (List.minimum values)))
  in
    AxisProps (lowest allX) (lowest allY) (highest allX) (highest allY)


{- Draw line -}
viewLine : ((Float, Float) -> (String, String)) -> (Float, Float, Float, Float) -> Svg.Svg a
viewLine toSvgCoords' (x1, y1, x2, y2) =
  let
    (svgX1, svgY1) = toSvgCoords' (x1, y1)
    (svgX2, svgY2) = toSvgCoords' (x2, y2)
  in
    viewSvgLine svgX1 svgY1 svgX2 svgY2


{- Draw series -}
viewSeries : ((Float, Float) -> (String, String)) -> SerieConfig data -> data -> Svg.Svg a
viewSeries toSvgCoords' config data =
  let
    style' =
      "fill: none; stroke: " ++ config.color ++ ";"

    instructions =
      config.toCoords data
      |> List.map toSvgCoords'
      |> List.map (\(x, y) -> "L " ++ x ++ " " ++ y)
      |> String.join ","
  in
    Svg.path [ d ("M 0 0" ++ instructions), style style' ] []
