module Thrift.Protocol.JSON.Base64
  ( encodeBase64
  , encodeBase64Text
  , decodeBase64
  ) where

import Data.Bits
import Data.ByteString.Builder
import Data.ByteString.Builder.Prim as Prim
import Data.ByteString.Internal
import Data.ByteString.Lazy (toStrict)
import Data.Text (Text)
import Data.Word
import Data.Vector ((!))
import qualified Data.ByteString as BS
import qualified Data.Text as Text
import qualified Data.Vector as Vector

symbol :: Word8 -> Word8
symbol w = BS.index
  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
  (fromIntegral w)

encodeBase64 :: ByteString -> Builder
encodeBase64 = encode . BS.unpack
  where
    -- case 1: len >= 3
    encode (b0 : b1 : b2 : bs) = primFixed
      (Prim.word8 >*< Prim.word8 >*< Prim.word8 >*< Prim.word8)
      (symbol $ (b0 `shiftR` 2) .&. 0x3f,
       (symbol $ ((b0 `shiftL` 4) .&. 0x30) .|. ((b1 `shiftR` 4) .&. 0x0f),
        (symbol $ ((b1 `shiftL` 2) .&. 0x3c) .|. ((b2 `shiftR` 6) .&. 0x03),
         symbol $ b2 .&. 0x3f))) <>
      encode bs
    -- case 2: len == 2
    encode [b0, b1] = primFixed
      (Prim.word8 >*< Prim.word8 >*< Prim.word8)
      (symbol $ (b0 `shiftR` 2) .&. 0x3f,
       (symbol $ ((b0 `shiftL` 4) .&. 0x30) .|. ((b1 `shiftR` 4) .&. 0x0f),
        symbol $ (b1 `shiftL` 2) .&. 0x3c))
    -- case 3: len == 1
    encode [b0] = primFixed
      (Prim.word8 >*< Prim.word8)
      (symbol $ (b0 `shiftR` 2) .&. 0x3f,
       symbol $ (b0 `shiftL` 4) .&. 0x30)
    -- case 4: len == 0 (impossible)
    encode [] = mempty

encodeBase64Text :: ByteString -> Text
encodeBase64Text =
  Text.pack . map w2c . BS.unpack . toStrict . toLazyByteString . encodeBase64

decodeTable :: Word8 -> Word8
decodeTable = (table!) . fromIntegral
  where
    table = Vector.fromList
      [ 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
      , 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
      , 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
      , 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x3e, 0xff, 0xff, 0xff, 0x3f
      , 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3a, 0x3b, 0x3c, 0x3d, 0xff, 0xff
      , 0xff, 0xff, 0xff, 0xff, 0xff, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06
      , 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f, 0x10, 0x11, 0x12
      , 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0xff, 0xff, 0xff, 0xff, 0xff
      , 0xff, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f, 0x20, 0x21, 0x22, 0x23, 0x24
      , 0x25, 0x26, 0x27, 0x28, 0x29, 0x2a, 0x2b, 0x2c, 0x2d, 0x2e, 0x2f, 0x30
      , 0x31, 0x32, 0x33, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
      , 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
      , 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
      , 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
      , 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
      , 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
      , 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
      , 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
      , 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
      , 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
      , 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
      , 0xff, 0xff, 0xff, 0xff
      ]

decodeBase64 :: ByteString -> ByteString
decodeBase64 = BS.pack . decode . BS.unpack
  where
    decode (b0 : b1 : b2 : b3 : bs) =
      decode0 b0 b1 : decode1 b1 b2 : decode2 b2 b3 : decode bs
    decode [b0, b1, b2] = [decode0 b0 b1, decode1 b1 b2]
    decode [b0, b1] = [decode0 b0 b1]
    decode _ = []

    decode0 b0 b1 =
      (decodeTable b0 `shiftL` 2) .|.
      (decodeTable b1 `shiftR` 4)
    decode1 b1 b2 =
      ((decodeTable b1 `shiftL` 4) .&. 0xf0) .|.
      (decodeTable b2 `shiftR` 2)
    decode2 b2 b3 =
      ((decodeTable b2 `shiftL` 6) .&. 0xc0) .|.
      decodeTable b3