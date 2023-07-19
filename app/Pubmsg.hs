module Main where

import qualified Data.ByteString as BS

import Network.Run.TCP
import Network.Socket.ByteString.Lazy (recv, sendAll)

import System.IO
import System.Exit
import System.Posix.IO
import System.Posix.Types
import System.Posix.Process

import Piped
import Codec.Serialise

-- TODO: make this generic to remove duplicate func in submsg
registerTopic :: IO CPid
registerTopic = runTCPClient "127.0.0.1" "4242" $ \s -> do
  pid <- getProcessID
  let req = serialise (Publisher (show pid))
  sendAll s req
  res <- deserialise <$> recv s 1024
  case res of
    () -> return pid

writeNamedPipe :: FilePath -> IO ()
writeNamedPipe pipePath = do
  fd <- openFd pipePath ReadWrite Nothing defaultFileFlags
  h <- fdToHandle fd
  hSetBuffering h LineBuffering

  mapM_ ((BS.hPut h . flip BS.snoc 0xA)  =<<) lines'

  hClose h
  closeFd fd

lines' :: [IO BS.ByteString]
lines' = repeat BS.getLine

main :: IO ()
main = do
  topic <- registerTopic
  writeNamedPipe (show topic)
