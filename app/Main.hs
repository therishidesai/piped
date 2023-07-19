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
publisherWorker h subs = forever $ do
  l <- BS.hGetLine h
  s <- readMVar subs
  let ll = BS.snoc l 0xA
  mapM_ (`BS.hPut` ll) s

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
