{-# LANGUAGE DeriveGeneric #-}

module Piped where

import Codec.Serialise

import GHC.Generics

data Req = Publisher { topic :: String }
        |  Subscriber { topic :: String }
        deriving (Generic)
instance Serialise Req
