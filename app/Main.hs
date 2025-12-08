{-# LANGUAGE OverloadedStrings #-}
{-# OPTIONS_GHC -Wno-unrecognised-pragmas #-}
{-# HLINT ignore "Use camelCase" #-}
module Main where

import Crypto.Hash (SHA256(..), hashWith)
import Data.ByteArray.Encoding (convertToBase, Base(..))
import Data.ByteString (ByteString)
import qualified Data.ByteString as B
import Control.Applicative ((<|>))

-- Hash utilities
h :: ByteString -> ByteString
h = convertToBase Base16 . hashWith SHA256

tag :: ByteString -> [ByteString] -> ByteString
tag t xs = h (B.concat (t : xs))

mk :: ByteString -> [ByteString] -> String -> SemHash
mk tg xs = SemHash (tag tg xs)

-- Terms
data Term
  = S | K | I
  | App Term Term
  deriving (Eq, Show)

data SemHash = SemHash
  { digest :: ByteString
  , desc   :: String
  } deriving (Show, Eq)

-- Semantic hashing

hashTerm :: Term -> SemHash
hashTerm S         = mk "S"   []     "S"
hashTerm K         = mk "K"   []     "K"
hashTerm I         = mk "I"   []     "I"

hashTerm (App f x) =
  let hf = digest (hashTerm f)
      hx = digest (hashTerm x)
  in case (f, x) of
       (App K a, b) ->
         mk "K_RULE" [digest (hashTerm a), digest (hashTerm b)]
                      "K-reduction-redex"

       (I, y) ->
         mk "I_RULE" [digest (hashTerm y)]
                      "I-reduction-redex"

       (App (App S f1) g1, x1) ->
         mk "S_RULE" [digest (hashTerm f1), digest (hashTerm g1), digest (hashTerm x1)]
                     "S-reduction-redex"

       (App S f1, g1) ->
         mk "S_WAIT2" [digest (hashTerm f1), digest (hashTerm g1)]
                      "partial-S (needs x)"

       (S, f1) ->
         mk "S_WAIT1" [digest (hashTerm f1)]
                      "partial-S (needs g, x)"

       _ ->
         mk "APP" [hf, hx] "structural application"

-- reduction
reduce :: Term -> Maybe Term
reduce (App f x) =
  case (f, x) of

    -- K-rule
    (App K a, _) -> Just a

    -- I-rule
    (I, x1) -> Just x1

    -- S-rule
    (App (App S f1) g1, x1) ->
        Just (App (App f1 x1) (App g1 x1))

    -- Otherwise try to reduce left, then right
    _ -> App <$> reduce f <*> pure x
         <|> App f <$> reduce x

reduce _ = Nothing


-- The reduction step
data Step = Step
  { beforeHash :: SemHash
  , afterHash  :: SemHash
  , rule       :: String
  , termAfter  :: Term
  } deriving (Show)

reduceStep :: Term -> Maybe Step
reduceStep t = do
  new <- reduce t
  let oldH = hashTerm t
  let newH = hashTerm new
  return (Step oldH newH (desc newH) new)

-- Examples
ski_I :: Term
ski_I = App (App S K) K   -- SKK

example :: Term
example = App ski_I (App S K)

demo :: IO ()
demo = do
  putStrLn "SKK semantic hash:"
  print (hashTerm ski_I)

  putStrLn "\nOne reduction step of SKK:"
  print (reduceStep ski_I)

  putStrLn "\nReduction of example:"
  print (reduceStep example)

main :: IO ()
main = demo
