module Main where

import qualified Data.ByteString as BS
import qualified Data.ByteString.Lazy as BSL
import qualified Data.ByteString.Lazy.Char8 as BSC

import Network.Run.TCP
import Network.Socket.ByteString.Lazy

import System.IO
import System.Posix.IO
import System.Posix.Files

import Piped
import Codec.Serialise

import Control.Monad

import Control.Concurrent

publisherWorker :: Handle -> MVar [Handle] -> IO ()
publisherWorker h subs = do
  l <- BSC.hGetContents h
  s <- readMVar subs
  mapM_ (`BSC.hPut` l) s

-- subscriberWorker :: MVar [Handle] -> Chan BS.ByteString -> IO ()
-- subscriberWorker subs dq = forever $ do
--   d <- readChan dq
--   s <- readMVar subs
--   mapM_ (`BS.hPut` d) s

main :: IO ()
main = do
  subs <- newMVar []
  -- dataq <- newChan
  -- _ <- forkIO (subscriberWorker subs dataq)
  runTCPServer Nothing "4242" $ talk subs
  where
    talk subs conn = do
        msg <- deserialise <$> recv conn 1024
        case msg of
          Publisher t -> do
            createNamedPipe t 0o777
            fd <- openFd t ReadWrite Nothing defaultFileFlags
            h <- fdToHandle fd
            hSetBuffering h LineBuffering
            _ <- forkIO (publisherWorker h subs)
            sendAll conn $ serialise ()

          Subscriber t -> do
            createNamedPipe t 0o777
            fd <- openFd t ReadWrite Nothing defaultFileFlags
            h <- fdToHandle fd
            hSetBuffering h LineBuffering
            subs' <- takeMVar subs
            putMVar subs $ h : subs'
            sendAll conn $ serialise ()
