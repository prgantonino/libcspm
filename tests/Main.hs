module Main where

import System.Directory
import System.Exit (exitFailure, exitSuccess)
import System.FilePath

import CSPM
import Monad
import Util.Exception
import Util.PrettyPrint

data RunResult = 
    ErrorOccured
    | WarningsEmitted
    | PassedNoWarnings
    deriving Eq
        
main :: IO ()
main = do
    tests <- runSections
    results <- sequence tests
    let
        failureCount = length results - successCount
        successCount = length (filter id results)
    putStrLn $ show $ 
        int failureCount <+> text "failures" 
        <+> int successCount <+> text "passes"
    if failureCount == 0 then exitSuccess else exitFailure

getAndFilterDirectoryContents :: FilePath -> IO [FilePath]
getAndFilterDirectoryContents fp = do
    b <- doesDirectoryExist fp
    if not b then return [] else do
        names <- getDirectoryContents fp
        return $ filter (`notElem` [".", "..", ".DS_Store"]) names

runSections ::IO [IO Bool]
runSections = do
    let testDir = "tests"
    sections <- getAndFilterDirectoryContents testDir
    fs <- mapM (\section -> do
            shouldPassFiles <- getAndFilterDirectoryContents $ 
                                joinPath [testDir, section, "should_pass"]
            shouldFailFiles <- getAndFilterDirectoryContents $ 
                                joinPath [testDir, section, "should_fail"]
            shouldWarnFiles <- getAndFilterDirectoryContents $
                                joinPath [testDir, section, "should_warn"]
            let 
                Just test = lookup section testFunctions
                pf = [runTest (joinPath [testDir, section, "should_pass", f]) 
                        test PassedNoWarnings | f <- shouldPassFiles]
                ff = [runTest (joinPath [testDir, section, "should_fail", f]) 
                        test ErrorOccured | f <- shouldFailFiles]
                wf = [runTest (joinPath [testDir, section, "should_warn", f]) 
                        test WarningsEmitted | f <- shouldWarnFiles]
            return $ pf++ff++wf
        ) sections
    return $ concat fs

runTest :: FilePath -> (FilePath -> Test a) -> RunResult -> IO Bool
runTest fp test expectedResult = do
    putStr $ "Running test "++fp++"..."
    s <- initTestState
    res <- tryM $ runTestM s $ do
        test fp
        getState lastWarnings
    let
        failed :: Maybe Doc -> IO Bool
        failed (Just e) = do
            putStrLn "FAILED"
            putStrLn $ show e
            return False
        failed Nothing = do
            putStrLn "FAILED"
            return False
        passed = do
            putStrLn "Passed"
            return True
        
        shouldPass = expectedResult == PassedNoWarnings
        shouldFail = expectedResult == ErrorOccured
        shouldWarn = expectedResult == WarningsEmitted
    case res of 
        Left (SourceError e) -> if shouldFail then passed else failed (Just (prettyPrint e))
        Right [] -> if shouldPass then passed else failed Nothing
        Right ws -> if shouldWarn then passed else failed (Just (prettyPrint ws))
        _ -> failed (Just (text "Internal Error"))

testFunctions = [
        ("parser", parserTest),
        ("typechecker", typeCheckerTest),
        ("prettyprinter", prettyPrinterTest)
    ]

typeCheckerTest :: FilePath -> Test ()
typeCheckerTest fp = do
    ms <- parseFile fp
    typeCheckFile ms
    return ()

parserTest :: FilePath -> Test ()
parserTest fp = do
    ms <- parseFile fp
    -- Force evaluation of the whole of ms. We can't just use seq
    -- as this would leave thunks in the data structure. Instead we take
    -- the length of the string representing ms and then compute the length
    (length (show ms)) `seq` (return ())

prettyPrinterTest :: FilePath -> Test ()
prettyPrinterTest fp = do
    ms <- parseFile fp
    let str = show (prettyPrint ms)
    ms' <- parseStringAsFile str
    if ms /= ms' then throwException UserError else return ()