{-# LANGUAGE OverloadedStrings #-}

-- Known issues
--
-- [todo] - Parser doesn't understand precedence with braces
module Test.Parser
    ( tests
    ) where

import Protolude hiding (bool)

import Olifant.Core
import Olifant.Parser

import Test.Tasty
import Test.Tasty.HUnit

tests :: TestTree
tests = testGroup "Parser" ts
  where
    ts = [literals, lam, combinators, application, let', ll, alias]

literals :: TestTree
literals =
    testCase "Literal numbers, identifiers and booleans" $ do
        expect "42" [CLit $ Number 42]
        expect "-26" [CLit $ Number (-26)]
        expect "#f" [CLit $ Bool False]
        expect "#t" [CLit $ Bool True]
        expect "hello" [CVar "hello"]

lam :: TestTree
lam =
    testCase "λ definitions" $
    -- Identity function
     do
        expect "λx.x" [CLam "λ" [(TUnit, "x")] (CVar "x")]
        expect "λx:b.x" [CLam "λ" [(TBool, "x")] (CVar "x")]
        expect "λx:i.x" [CLam "λ" [(TInt, "x")] (CVar "x")]

combinators :: TestTree
combinators =
    testCase "Combinators" $
    -- K combinator
    expect "λx.λy.x" [CLam "λ" [(TUnit, "x")] (CLam "λ" [(TUnit, "y")] (CVar "x"))]
    -- S combinator
    -- expect "λx.λy.λz.x z y z" [Lam "x" TUnit
    --                             (Lam "y" TUnit
    --                              (Lam "z" TUnit
    --                                (App (Var "x")
    --                                 (App (Var "z") (App (Var "y") (Var "z"))))))]
    --
    -- B combinator
    -- expect "λx.λy.λz.x y z" [Lam "x" TUnit
    --                           (Lam "y" TUnit
    --                             (Lam "z" TUnit (App (Var "x") (App (Var "y") (Var "z")))))]

application :: TestTree
application =
    testCase "λ application" $ do
        expect "a b" d
    -- Handle some spaces correctly
        expect " a  b " d
        expect "a   b" d
  where
    d = [CApp (CVar "a") [CVar "b"]]

let' :: TestTree
let' =
    testCase "Let expressions" $ do
        expect "let a = 1" [CLet "a" (CLit $ Number 1)]
        expect "let a   =   1" [CLet "a" (CLit $ Number 1)]
        expect "let   a = 1" [CLet "a" (CLit $ Number 1)]
        expect "let id = /x.x" [CLet "id" (CLam "id" [x] (CVar "x"))]
  where
    x = (TUnit, "x")

alias :: TestTree
alias =
    testCase "Let bindings with aliases" $
    expect "let f = id" [CLet "f" (CVar "id")]

ll :: TestTree
ll =
    testCase "Handle sequences of expressions" $ do
        expect "1; 1" [a, a]
        expect "1;1" [a, a]
        expect "1 1" [CApp a [a]]
        expect "1 2 3" [CApp a [CLit $ Number 2, CLit $ Number 3]]
        expect "/x.x; 1" [CLam "λ" [x] (CVar "x"), a]
        expect
            "let id = /x.x; id 1"
            [CLet "id" (CLam "id" [x] (CVar "x")), CApp (CVar "id") [a]]
  where
    a = CLit $ Number 1
    x = (TUnit, "x")

-- inline :: TestTree
-- inline =
--     testCase "Support inline operators" $
--     expect "let f = /a:i b:i.a + b; f 1 2" []

-- * Helper functions
expect :: Text -> [Calculus] -> Assertion
expect text expectation = parse text @?= Right expectation
