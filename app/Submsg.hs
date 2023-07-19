module Main where

import Network.Run.TCP
import Network.Socket.ByteString.Lazy (recv, sendAll)

import System.IO
import System.Exit
import System.Posix.IO
import System.Posix.Types
import System.Posix.Process

import Piped
import Codec.Serialise

-- TODO: make this generic to remove duplicate func in pubmsg
registerTopic :: IO CPid
registerTopic = runTCPClient "127.0.0.1" "4242" $ \s -> do
  pid <- getProcessID
  let req = serialise (Subscriber (show pid))
  sendAll s req
  res <- deserialise <$> recv s 1024
  case res of
    () -> return pid

readNamedPipe :: FilePath -> IO ()
readNamedPipe pipePath = do
  fd <- openFd pipePath ReadOnly Nothing defaultFileFlags
  h <- fdToHandle fd

  readLines h

  hClose h
  closeFd fd

readLines :: Handle -> IO ()
readLines h = do
  line <- hGetLine h
  putStrLn line
  readLines h

main :: IO ()
main = do
  topic <- registerTopic
  readNamedPipe (show topic)
