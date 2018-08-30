{-# LANGUAGE TypeFamilies #-}
module Stuff where

data family T a

-- NOTE: Uncomment this line to make it
-- work again.
data instance T Int = T Int

test :: String
test =
  "test"
