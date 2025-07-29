module Main where

main :: IO ()
main = putStr $ unlines $ hexagons 12 17

hexagons :: Int -> Int -> [String]
hexagons xRepeat yRepeat =
  yRepeat `times` [xRepeat `times` "/ \\_"
                  ,xRepeat `times` "\\_/ "]
  where
    n `times` l = concat (replicate n l)
