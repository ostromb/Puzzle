{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
-- base
import Control.Exception (IOException)
import qualified Control.Exception as Exception
import qualified Data.Foldable as Foldable
import Control.Concurrent
import Control.Monad
import Control.Monad.Loops

-- bytestring
import Data.ByteString.Lazy (ByteString)
import qualified Data.ByteString.Lazy as BL

-- cassava
import Data.Csv
  ( DefaultOrdered(headerOrder)
  , FromField(parseField)
  , FromRecord(parseRecord)
  , Header
  , ToField(toField)
  , ToNamedRecord(toNamedRecord)
  , (.:)
  , (.=)
  )
import qualified Data.Csv as Cassava
import Data.Either

-- text
import Data.Text (Text)
import qualified Data.Text.Encoding as Text
import qualified Data.Text as T
import qualified Data.Text.IO as T

-- vector
import Data.Vector (Vector)
import qualified Data.Vector as Vector

-- websockets
import qualified Network.WebSockets as WS
import Data.Traversable (for)
import Network.WebSockets (sendTextData)
import qualified Data.Text.Internal.Fusion.Size as Vector
import qualified Data.Text.Internal.Lazy as Vector

data Puzzle =
  Puzzle
    { puzzleID :: Text
    , fen :: Text
    , moves :: Text
    , rating :: Int
    , deviation :: Int
    , popularity :: Int
    , nbPlays :: Int
    , themes :: Text
    , link :: Text}
    deriving (Eq, Show)

instance FromRecord Puzzle where
  parseRecord m = Puzzle
      <$> m Cassava..! 0
      <*> m Cassava..! 1 
      <*> m Cassava..! 2 
      <*> m Cassava..! 3 
      <*> m Cassava..! 4             
      <*> m Cassava..! 5              
      <*> m Cassava..! 6            
      <*> m Cassava..! 7         
      <*> m Cassava..! 8       

decodePuzzle :: ByteString -> Either String (Vector Puzzle)
decodePuzzle = do
  Cassava.decode Cassava.NoHeader
  
main :: IO ()
main = do
  print "Server is running"
  WS.runServer "127.0.0.1" 1234 application

application :: WS.PendingConnection -> IO ()
application pending = do
  con <- WS.acceptRequest pending
  WS.withPingThread con 30 (return ()) $ do
    csvData <- BL.readFile "1400_1600.csv"
    let (x,xlist) =  partitionEithers [decodePuzzle csvData]
    mv <- newEmptyMVar
    forever $ do
      loopFunc con (head xlist) mv
      readMVar mv >>= print

recvFunc :: WS.Connection -> [Text] -> [Text] -> IO ()
recvFunc con [] [] = WS.sendTextData con ("PUZZLE_COMPLETE" :: Text)
recvFunc con checklist sendlist = do
  msg  <- WS.receiveData con
  if msg /= head checklist
     then do
       WS.sendTextData con ("WRONG_MOVE" :: Text)
       recvFunc con checklist sendlist
     else do
       sendFunc con (head sendlist)
       recvFunc con (tail checklist) (tail sendlist)


sendFunc :: WS.Connection -> Text -> IO ()
sendFunc con move = do 
  WS.sendTextData con move
  print move

loopFunc :: WS.Connection -> Vector Puzzle -> MVar Text -> IO ()
loopFunc con x mv = do
  puz <- Vector.headM x
  let movelist = T.words (moves puz)
  WS.sendTextData con (fen puz :: Text)
  WS.sendTextData con (head movelist)
  recvFunc con (first (tail movelist)) (second (tail movelist) ++ [T.pack ("done")])
  if Vector.length x > 1 
     then do 
       loopFunc con (Vector.tail x) mv
     else do
       readMVar mv >>= print



first :: [a] -> [a]
first [] = []
first (x:xs) = x:second xs

second :: [a] -> [a]
second [] = []
second (x:xs) = first xs
