module Util.Annotated where

import Prelude
import Util.Exception
import Util.Prelude
import Util.PrettyPrint

data SrcLoc = 
	SrcLoc {
		srcLocFile :: String,
		srcLocLine :: !Int,
		srcLocCol :: !Int
	}
	| NoLoc
	deriving Eq
	
instance Ord SrcLoc where
	(SrcLoc f1 l1 c1) `compare` (SrcLoc f2 l2 c2) =
		(f1 `compare` f2) `thenCmp` 
		(l1 `compare` l2) `thenCmp` 
		(c1 `compare` c2)
	NoLoc `compare` NoLoc = EQ
	NoLoc `compare` _ = LT
	_ `compare` NoLoc = GT
	
-- From GHC
data SrcSpan = 
	SrcSpanOneLine { 
		srcSpanFile :: String,
		srcSpanLine :: !Int,
		srcSpanSCol :: !Int,
		srcSpanECol :: !Int
	}
	| SrcSpanMultiLine { 
		srcSpanFile :: String,
		srcSpanSLine :: !Int,
		srcSpanSCol :: !Int,
		srcSpanELine :: !Int,
		srcSpanECol :: !Int
	}
	| SrcSpanPoint { 
		srcSpanFile	:: String,
		srcSpanLine :: !Int,
		srcSpanCol :: !Int
	}
	| Unknown
	deriving Eq
	
srcSpanStart :: SrcSpan -> SrcLoc
srcSpanStart (SrcSpanOneLine f l sc ec) = SrcLoc f l sc
srcSpanStart (SrcSpanMultiLine f sl sc el ec) = SrcLoc f sl sc
srcSpanStart (SrcSpanPoint f l c) = SrcLoc f l c
srcSpanStart Unknown = NoLoc

srcSpanEnd :: SrcSpan -> SrcLoc
srcSpanEnd (SrcSpanOneLine f l sc ec) = SrcLoc f l ec
srcSpanEnd (SrcSpanMultiLine f sl sc el ec) = SrcLoc f el ec
srcSpanEnd (SrcSpanPoint f l c) = SrcLoc f l c
srcSpanEnd Unknown = NoLoc

-- We want to order SrcSpans first by the start point, then by the end point.
instance Ord SrcSpan where
	a `compare` b = 
		(srcSpanStart a `compare` srcSpanStart b) `thenCmp` 
		(srcSpanEnd   a `compare` srcSpanEnd   b)

instance Show SrcSpan where
	show s = show (prettyPrint s)

instance PrettyPrintable SrcSpan where
	prettyPrint (SrcSpanOneLine f sline scol1 ecol1) = 
		text f <> colon <> int sline <> colon <> int scol1 <> char '-' <> int ecol1
	prettyPrint (SrcSpanMultiLine f sline scol eline ecol) = 
		text f <> colon <> int sline <> colon <> int scol
						<> char '-' 
						<> int eline <> colon <> int ecol
	prettyPrint (SrcSpanPoint f sline scol) = 
		text f <> colon <> int sline <> colon <> int scol
	prettyPrint Unknown = text "<unknown location>"
	
combineSpans :: SrcSpan -> SrcSpan -> SrcSpan
combineSpans s1 s2 | srcSpanFile s1 /= srcSpanFile s2 = 
	panic "Cannot combine spans as they span files"
combineSpans (SrcSpanOneLine f1 line1 scol1 ecol1) 
		(SrcSpanOneLine f2 line2 scol2 ecol2) = 
	if line1 == line2 then SrcSpanOneLine f1 line1 scol1 ecol2
	else SrcSpanMultiLine f1 line1 scol1 line2 ecol2
combineSpans (SrcSpanOneLine f1 sline1 scol1 ecol1) 
		(SrcSpanMultiLine f2 sline2 scol2 eline2 ecol2) = 
	SrcSpanMultiLine f1 sline1 scol1 eline2 ecol2
combineSpans (SrcSpanMultiLine f1 sline1 scol1 eline1 ecol1)
		(SrcSpanOneLine f2 eline2 scol2 ecol2) =
	SrcSpanMultiLine f1 sline1 scol1 eline2 ecol2
combineSpans (SrcSpanMultiLine f1 sline1 scol1 eline1 ecol1) 
		(SrcSpanMultiLine f2 sline2 scol2 eline2 ecol2) =
	SrcSpanMultiLine f1 sline1 scol1 eline2 ecol2

data Located a = 
	L {
		locatedLoc :: SrcSpan,
		locatedInner :: a 
	}
	
data Annotated a b = 
	An {
		loc :: SrcSpan,
		annotation :: a,
		inner :: b
	}

dummyAnnotation :: a
dummyAnnotation = panic "Dummy annotation evaluated"

unAnnotate :: Annotated a b -> b
unAnnotate (An _ _ b) = b
	
instance Show b => Show (Annotated a b) where
	show (An _ _ b) = show b
instance Show a => Show (Located a) where
	show (L _ a) = show a
	
instance (PrettyPrintable b) => PrettyPrintable (Annotated a b) where
	prettyPrint (An loc typ inner) = prettyPrint inner
instance (PrettyPrintable a) => PrettyPrintable (Located a) where
	prettyPrint (L loc inner) = prettyPrint inner

instance Eq b => Eq (Annotated a b) where
	(An _ _ b1) == (An _ _ b2) = b1 == b2
instance Eq a => Eq (Located a) where
	(L _ b1) == (L _ b2) = b1 == b2