{
{-# OPTIONS_GHC -fno-warn-lazy-unlifted-bindings #-}
module CSPM.Parser.Lexer where

import Data.List

import Control.Monad.Trans
import CSPM.DataStructures.Tokens
import CSPM.Parser.Exceptions
import CSPM.Parser.Monad
import Util.Annotated
import Util.Exception

}

$digit      = [0-9]
$whitechar   = [\ \n\r\f\v\t]
$white_no_nl = $whitechar # \n
$not_white = [^$whitechar]
$alpha = [A-Za-z]
$upperalpha = [A-Z]
$alphaspace = [ $alpha]
$alphanum = [A-Za-z0-9_]
$propertychars = [A-Za-z0-9\ _\-]
$prime = '
$notid = [[^0-9a-zA-Z_]\(\[$whitechar]

@property = $propertychars+(\[$upperalpha+\])?

@white_no_nl = ((\-\-.*)|$white_no_nl)+
@nl = ((\-\-.*\n)|$whitechar)*
@comment = (\-\-.*) 
@nltok = (@comment|())\n@nl

-- *************************************************************************
-- TODO: get correct lambda function syntax

-- Note that we allow newlines to preceed all tokens, except for those that
-- may possibly be at the start of a new expression. Therefore, for example,
-- as a + may never be at the start of an expression we allow newlines before
-- them. However, - and < may either appear in the middle of an expression or
-- the start of one and thus we do not allow newlines to come between them.
tokens :-
	<semantic_property>"tau priority"		{ tok TTauPriority }
	<semantic_property>"tau priority over"	{ tok TTauPriority }
	<semantic_property>"deadlock free"		{ tok TDeadlockFree }
	<semantic_property>"deadlock-free"		{ tok TDeadlockFree }
	<semantic_property>"livelock free"		{ tok TLivelockFree }
	<semantic_property>"livelock-free"		{ tok TLivelockFree }
	<semantic_property>"divergence free"	{ tok TDivergenceFree }
	<semantic_property>"divergence-free"	{ tok TDivergenceFree }
	<semantic_property>"deterministic"		{ tok TDeterministic }
	<semantic_property>@nl"[T]				{ tok TTracesModel }
	<semantic_property>@nl"[F]				{ tok TFailuresModel }
	<semantic_property>@nl"[FD]				{ tok TFailuresDivergencesModel }
	<semantic_property>"]:"					{ begin 0 }
	<semantic_property>"]"					{ begin 0 }

	<soak>((\-\-.*\n)|$whitechar)+			{ skip }
	<soak>""/$not_white						{ begin 0 }

	<0>@white_no_nl				{ skip }

	-- Comments
--	<0>"--".*					{ skip }
	<0>@nl"{-"					{ nestedComment }

	<0>@nl:\[					{ begin semantic_property }
	<0>@nl"[T="@nl				{ tok TTraceRefines }
	<0>@nl"[F="@nl				{ tok TFailuresRefines }
	<0>@nl"[FD="@nl				{ tok TFailuresDivergencesRefines }

	<0>@nl"false"/$notid		{ tok TFalse }
	<0>@nl"true"/$notid			{ tok TTrue }

	<0>"include".*$whitechar*\n	{ switchInput }

	-- Process Syntax
	<0>@nl"[]"@nl				{ tok TExtChoice }
	<0>@nl"|~|"@nl				{ tok TIntChoice }
	<0>@nl"|||"@nl				{ tok TInterleave }
	<0>@nl"/\"@nl				{ tok TInterrupt }
	<0>@nl"->"@nl				{ tok TPrefix }
	<0>@nl"[>"@nl				{ tok TSlidingChoice }
	<0>@nl"|>"@nl				{ tok TRException }
	<0>@nl"||"@nl				{ tok TParallel }
	<0>@nl";"@nl				{ tok TSemiColon }
	<0>@nl"&"@nl				{ tok TGuard }

	-- Boolean Operators
	<0>@nl"and"/$notid			{ soakTok TAnd }
	<0>@nl"or"/$notid			{ soakTok TOr }
	<0>@nl"not"/$notid			{ soakTok TNot }
	<0>@nl"=="@nl				{ tok TEq }
	<0>@nl"!="@nl				{ tok TNotEq }
	<0>@nl"<="@nl				{ tok TLtEq }
	<0>@nl">="@nl				{ tok TGtEq }
	-- We need a empty sequence token since the parser will not execute the
	<0>"<"$whitechar*">"		{ tok TEmptySeq }
	<0>"<"@nl					{ tok TLt }
	<0>@nl">"					{ gt }

	-- Parenthesis
	<0>"("@nl					{ openseq TLParen }
	<0>@nl")"					{ closeseq TRParen }
	<0>"{|"@nl					{ openseq TLPipeBrace }
	<0>@nl"|}"					{ closeseq TRPipeBrace }
	<0>"{"@nl					{ openseq TLBrace }
	<0>@nl"}"					{ closeseq TRBrace }
	<0>@nl"[["@nl				{ openseq TLDoubleSqBracket }
	<0>@nl"]]"					{ closeseq TRDoubleSqBracket }
	<0>@nl"[|"@nl				{ openseq TLPipeSqBracket }
	<0>@nl"|]"@nl				{ closeseq TRPipeSqBracket }
	<0>@nl"["@nl				{ tok TLSqBracket }
	<0>@nl"]"@nl				{ tok TRSqBracket }

	-- General Symbols
	<0>@nl"|"@nl				{ tok TPipe }
	<0>@nl","@nl				{ tok TComma }
	<0>@nl".."@nl				{ tok TDoubleDot }
	<0>@nl"."@nl				{ tok TDot }
	<0>@nl"?"@nl				{ tok TQuestionMark }
	<0>@nl"!"@nl				{ tok TExclamationMark }
	<0>@nl"<-"@nl				{ tok TDrawnFrom }
	<0>@nl"<->"@nl				{ tok TTie }
	<0>@nl":"@nl				{ tok TColon }

	<0>@nl"@@"@nl				{ tok TDoubleAt }

	-- Program Structure
	<0>@nl"="@nl				{ tok TDefineEqual }
	<0>@nl"if"/$notid			{ soakTok TIf }
	<0>@nl"then"/$notid			{ soakTok TThen }
	<0>@nl"else"/$notid			{ soakTok TElse }
	<0>@nl"let"/$notid			{ soakTok TLet }
	<0>@nl"within"/$notid		{ soakTok TWithin }
	<0>"channel"/$notid			{ soakTok TChannel }
	<0>"assert"/$notid			{ soakTok TAssert }
	<0>"datatype"/$notid		{ soakTok TDataType }
	<0>"external"/$notid		{ soakTok TExternal }
	<0>"transparent"/$notid		{ soakTok TTransparent }
	<0>"nametype"/$notid		{ soakTok TNameType }

	<0>@nl"\"@nl				{ tok TBackSlash }
	<0>@nl"@"@nl				{ tok TLambdaDot }

	-- Arithmetic
	<0>@nl"+"@nl				{ tok TPlus }
	<0>"-"@nl					{ tok TMinus }
	<0>@nl"*"@nl				{ tok TTimes }
	<0>@nl"/"@nl				{ tok TDivide }
	<0>@nl"%"@nl				{ tok TMod }

	-- Sequence Symbols
	<0>@nl"^"@nl				{ tok TConcat }
	<0>"#"@nl					{ tok THash }

	-- 'Wildcards'
	<0>$alpha$alphanum*$prime*	{ stok (\s -> TIdent s) }
	<0>@nl$digit+				{ stok (\ s -> TInteger (read s)) }

	-- Must be after names
	<0>@nl"_"@nl				{ tok TWildCard }

	<0>@nltok					{ tok TNewLine }

{
wschars :: String
wschars = " \t\r\n"

strip :: String -> String
strip = lstrip . rstrip

-- | Same as 'strip', but applies only to the left side of the string.
lstrip :: String -> String
lstrip s = case s of
	[] -> []
	(x:xs) -> if elem x wschars then lstrip xs else s

-- | Same as 'strip', but applies only to the right side of the string.
rstrip :: String -> String
rstrip = reverse . lstrip . reverse

openseq token inp len = 
	do
		--cs <- getSequenceStack
		--setSequenceStack (0:cs)
		tok token inp len
closeseq token inp len = 
	do
		--(c:cs) <- getSequenceStack
		--setSequenceStack cs
		tok token inp len

gt :: AlexInput -> Int -> ParseMonad LToken
gt inp len = do
	(c:cs) <- getSequenceStack
	tok (if c > 0 then TCloseSeq else TGt) inp len

soakTok :: Token -> AlexInput -> Int -> ParseMonad LToken
soakTok t inp len = setCurrentStartCode soak >> tok t inp len

-- TODO: don't count whitespace in the tokens
tok :: Token -> AlexInput -> Int -> ParseMonad LToken
tok t (ParserState { fileStack = fps:_ }) len =
		return $ L (SrcSpanOneLine f lineno colno (colno+len)) t
	where
		(FileParserState { tokenizerPos = FilePosition offset lineno colno, 
							fileName = f }) = fps

stok :: (String -> Token) -> AlexInput -> Int -> ParseMonad LToken
stok f (st @ ParserState { fileStack = fps:_ }) len =
		tok (f (filter (\ c -> c /= '\n') (take len s))) st len
	where
		(FileParserState { input = s }) = fps

skip input len = getNextToken

nestedComment :: AlexInput -> Int -> ParseMonad LToken
nestedComment _ _ = do
	st <- getParserState
	go 1 st
	where 
		err :: ParseMonad a
		err = do
			FileParserState { 
				fileName = fname, 
				tokenizerPos = pos, 
				currentStartCode = sc } <- getTopFileParserState
			throwSourceError [lexicalErrorMessage (filePositionToSrcLoc fname pos)]
		go :: Int -> AlexInput -> ParseMonad LToken
		go 0 st = do setParserState st; getNextToken
		go n st = do
			case alexGetChar st of
				Nothing  -> err
				Just (c,st) -> do
					case c of
						'-' -> do
							case alexGetChar st of
								Nothing			 -> err
								Just ('\125',st) -> go (n-1) st
								Just (c,st)      -> go n st
						'\123' -> do
							case alexGetChar st of
								Nothing		  -> err
								Just ('-',st) -> go (n+1) st
								Just (c,st)   -> go n st
						c -> go n st


-- TODO: soak setCurrentStartCode soak
switchInput :: AlexInput -> Int -> ParseMonad LToken
switchInput (st @ ParserState { fileStack = fps:_ }) len = 
		setCurrentStartCode soak >> pushFile file getNextToken
	where
		(FileParserState { input = s }) = fps
		str = take len s
		quotedFname = strip (drop (length "include") str)
		file = calcFile (drop 1 quotedFname)
		calcFile ('\"':cs) = ""
		calcFile (c:cs) = c:calcFile cs

type AlexInput = ParserState

begin :: Int -> AlexInput -> Int -> ParseMonad LToken
begin sc' st len = setCurrentStartCode sc' >> getNextToken

alexInputPrevChar :: AlexInput -> Char
alexInputPrevChar (ParserState { fileStack = fps:_ })= previousChar fps

alexGetChar :: AlexInput -> Maybe (Char,AlexInput)
alexGetChar (ParserState { fileStack = [] }) = Nothing
alexGetChar (st @ (ParserState { fileStack = fps:fpss })) = gc fps
	where
		gc (fps @ (FileParserState { input = [] })) = 
			alexGetChar (st { fileStack = fpss })
		gc (fps @ (FileParserState { tokenizerPos = p, input = (c:s) })) =
				p' `seq` Just (c, st')
			where
				p' = movePos p c
				fps' = fps { input = s, tokenizerPos = p', previousChar = c }
				st' = st { fileStack = fps':fpss }

getNextToken :: ParseMonad LToken
getNextToken = do
	FileParserState { 
		fileName = fname, 
		tokenizerPos = pos, 
		currentStartCode = sc } <- getTopFileParserState
	st <- getParserState
	case alexScan st sc of
		AlexEOF -> return $ L Unknown TEOF
		AlexError st' -> 
			throwSourceError [lexicalErrorMessage (filePositionToSrcLoc fname pos)]
		AlexSkip st' len -> do
			setParserState st'
			getNextToken
		AlexToken st' len action -> do
			setParserState st'
			action st len

getNextTokenWrapper :: (LToken -> ParseMonad a) -> ParseMonad a
getNextTokenWrapper cont = getNextToken >>= cont

}