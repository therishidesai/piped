module Main where

import qualified Data.ByteString.Char8 as BS
import qualified Data.ByteString.Lazy.Char8 as BSL

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
  chunks <- BSL.toChunks <$> BSL.hGetContents h
  forM_ chunks $ \chunk -> do
    subs' <- readMVar subs
    forM_ subs' $ \sub -> BS.hPut sub chunk

main :: IO ()
main = do
  subs <- newMVar []
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
            _ <- forkIO $ publisherWorker h subs
            sendAll conn $ serialise ()

          Subscriber t -> do
            createNamedPipe t 0o777
            fd <- openFd t ReadWrite Nothing defaultFileFlags
            h <- fdToHandle fd
            hSetBuffering h LineBuffering
            subs' <- takeMVar subs
            putMVar subs $ h : subs'
            sendAll conn $ serialise ()
