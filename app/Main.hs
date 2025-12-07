{-# LANGUAGE OverloadedStrings #-}

import Crypto.Hash (hashWith, SHA256(..), Digest)
import Data.ByteArray.Encoding (convertToBase, Base(Base16))
import Data.ByteString (ByteString)
import qualified Data.ByteString as B
import qualified Data.ByteString.Char8 as C

data SKI
  = S
  | K
  | I                        -- optional since I = S K K
  | App Term Term
  deriving (Eq, Show)

newtype Term = In SKI
  deriving (Eq, Show)

s :: Term
s = In S

k :: Term
k = In K

i :: Term
i = In I

app :: Term -> Term -> Term
app a b = In (App a b)

-- merkle hash the SKI Terms

-- hash to hex string
h :: ByteString -> ByteString
h bs = convertToBase Base16 (hashWith SHA256 bs)

-- serialize a term in a simple way
serialize :: Term -> ByteString
serialize (In S)      = "S"
serialize (In K)      = "K"
serialize (In I)      = "I"
serialize (In (App f x)) = "A(" <> serialize f <> "," <> serialize x <> ")"

-- Merkle hash of a full SKI term
merkle :: Term -> ByteString
merkle t = h ("NODE:" <> serialize t)

-- SKI reduction

-- Perform one step of SKI reduction, if we can
reduceOnce :: Term -> Maybe Term
reduceOnce (In (App (In (App (In (App (In S) f)) g)) x)) =
    -- S f g x  ->  f x (g x)
    Just $ app (app f x) (app g x)

-- there is a short-circuit: S K K is extensionally I
reduceOnce (In (App (In (App (In S) (In K))) (In K))) =
    Just i

reduceOnce (In (App (In (App (In K) a)) b)) =
    -- K a b -> a
    Just a

reduceOnce (In (App (In I) x)) =
    -- I x -> x
    Just x

-- Try reducing a subterm
reduceOnce (In (App f x)) =
    case reduceOnce f of
      Just f' -> Just (app f' x)
      Nothing ->
        case reduceOnce x of
          Just x' -> Just (app f x')
          Nothing -> Nothing

-- No reductions inside S/K/I
reduceOnce _ = Nothing

-- repeated reduction

nf :: Term -> Term
nf t = maybe t nf (reduceOnce t)

-- example programs

-- S K K = I
ski_I :: Term
ski_I = app (app s k) k  -- should reduce to I

-- example: ((S K K) x) -> x
example :: Term
example = app ski_I (app s k)  -- something arbitrary as "x"

main :: IO ()
main = do
  let t = ski_I
  putStrLn $ "Term: " ++ show t
  putStrLn $ "Merkle(t) = " ++ C.unpack (merkle t)

  let red = reduceOnce t
  putStrLn $ "One step reduction: " ++ show red

  putStrLn $ "NF(ski_I)   = " ++ show (nf ski_I)
  putStrLn $ "Merkle(NF)  = " ++ C.unpack (merkle (nf ski_I))

  putStrLn "\nExample application ((S K K) X):"
  putStrLn $ "  Before: " ++ show example
  putStrLn $ "  After:  " ++ show (nf example)
