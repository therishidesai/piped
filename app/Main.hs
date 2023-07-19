module Main where

import qualified Data.ByteString as BS
import qualified Data.ByteString.Char8 as BSC

import Network.Run.TCP
import Network.Socket.ByteString.Lazy

import System.IO
import System.Posix.IO
import System.Posix.Files

import Piped
import Codec.Serialise

import Control.Monad

import Control.Concurrent
import Control.Concurrent.STM


publisherWorker :: Handle -> TQueue BS.ByteString -> IO ()
publisherWorker h dq = forever $ do
  l <- BSC.hGetLine h
  print l
  atomically $ writeTQueue dq l

subscriberWorker :: MVar [Handle] -> TQueue BS.ByteString -> IO ()
subscriberWorker subs dq = forever $ do
  d <- atomically $ readTQueue dq
  s <- readMVar subs
  mapM_ (`BS.hPut` BS.snoc d 0xA) s

main :: IO ()
main = do
  subs <- newMVar []
  dataq <- newTQueueIO
  _ <- forkIO (subscriberWorker subs dataq)
  runTCPServer Nothing "4242" $ talk subs dataq
  where
    talk subs dataq conn = do
        msg <- deserialise <$> recv conn 1024
        case msg of
          Publisher t -> do
            putStrLn $ "Publisher: " ++ t
            createNamedPipe t 0o777
            fd <- openFd t ReadWrite Nothing defaultFileFlags
            h <- fdToHandle fd
            hSetBuffering h LineBuffering
            _ <- forkIO (publisherWorker h dataq)
            sendAll conn $ serialise ()

          Subscriber t -> do
            putStrLn $ "Subscriber: " ++ t
            createNamedPipe t 0o777
            fd <- openFd t ReadWrite Nothing defaultFileFlags
            h <- fdToHandle fd
            hSetBuffering h LineBuffering
            putStrLn "take the mvar"
            subs' <- takeMVar subs
            putStrLn "took the mvar"
            print subs'
            putMVar subs $ h : subs'
            sendAll conn $ serialise ()
