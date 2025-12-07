{-# LANGUAGE OverloadedStrings #-}

import Crypto.Hash (hashWith, SHA256(..), Digest)
import Data.ByteArray.Encoding (convertToBase, Base(Base16))
import Data.ByteString (ByteString)
import qualified Data.ByteString as B
import qualified Data.ByteString.Char8 as C

data SKI
  = S
  | K
  | I
  | App Term Term
  deriving (Eq, Show)

newtype Term = In SKI
  deriving (Eq, Show)

-- constructors
s = In S
k = In K
i = In I
app a b = In (App a b)

-- utilities

h :: ByteString -> ByteString
h bs = convertToBase Base16 (hashWith SHA256 bs)

serialize :: Term -> ByteString
serialize (In S)      = "S"
serialize (In K)      = "K"
serialize (In I)      = "I"
serialize (In (App f x)) = "A(" <> serialize f <> "," <> serialize x <> ")"

merkle :: Term -> ByteString
merkle t = h ("NODE:" <> serialize t)

stepHash :: ByteString -> Term -> ByteString
stepHash prev t = h ("STEP:" <> prev <> merkle t)

-- SKI reduction

reduceOnce :: Term -> Maybe Term
reduceOnce (In (App (In (App (In (App (In S) f)) g)) x)) =
    Just $ app (app f x) (app g x)

reduceOnce (In (App (In (App (In S) (In K))) (In K))) =
    Just i

reduceOnce (In (App (In (App (In K) a)) b)) =
    Just a

reduceOnce (In (App (In I) x)) =
    Just x

reduceOnce (In (App f x)) =
    case reduceOnce f of
      Just f' -> Just (app f' x)
      Nothing ->
        case reduceOnce x of
          Just x' -> Just (app f x')
          Nothing -> Nothing

reduceOnce _ = Nothing


reduceWithTrace :: Term -> (Term, [ByteString])
reduceWithTrace t0 = go t0 [merkle t0]  
  where
    go t acc =
      case reduceOnce t of
        Nothing -> (t, reverse acc)
        Just t' ->
          let hNext = stepHash (head acc) t'
          in go t' (hNext : acc)

-- example

ski_I = app (app s k) k
example = app ski_I (app s k)

main :: IO ()
main = do
  let (nfI, traceI) = reduceWithTrace ski_I
  putStrLn "Sequential hash chain for S K K:"
  mapM_ (putStrLn . C.unpack) traceI
  putStrLn ("Normal form: " ++ show nfI)

  let (nfEx, traceEx) = reduceWithTrace example
  putStrLn "\nSequential hash chain for ((S K K) X):"
  mapM_ (putStrLn . C.unpack) traceEx
  putStrLn ("Normal form: " ++ show nfEx)
