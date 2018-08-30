{-# LANGUAGE DeriveGeneric #-}
module Stuff where

import GHC.Generics

data X = X
-- NOTE: comment out the following line and
-- the ABI hash calculation will work again.
  deriving (Generic)

test :: String
test =
  "test"
