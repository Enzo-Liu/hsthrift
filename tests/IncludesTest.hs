--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements. See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership. The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- License); you may not use this file except in compliance
-- with the License. You may obtain a copy of the License at
--
--   http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing,
-- software distributed under the License is distributed on an
-- "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
-- KIND, either express or implied. See the License for the
-- specific language governing permissions and limitations
-- under the License.
--

module IncludesTest where

import qualified A.Types as A
import qualified B.Types as B
import qualified C.Types as C
import qualified D.Types as D
import qualified E.Types as E

-- If this compiles, then the test has passed
main :: IO ()
main = print a
  where
    a = A.A b c
    b = B.B d e
    c = C.C e
    d = D.D 0
    e = E.E ":)"