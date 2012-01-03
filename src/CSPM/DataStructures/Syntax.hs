-- | This module represents the abstract syntax tree of machine CSP.
-- Most of the datatypes are parameterised over the type of variables that they
-- contain. Before renaming (by 'CSPM.Renamer') the variables are of type 
-- 'UnRenamedName', wheras after renaming they are of type 'Name' (and are
-- hence associated with their bindings instances). Furthermore, nearly all
-- pieces of syntax are annoated with their location in the source code, and
-- (sometimes) with their type (but only after type checking). This is done 
-- using the 'Annotated' datatype.
module CSPM.DataStructures.Syntax (
    -- * Modules
    Module(..),
    -- * Declarations
    Decl(..), Match(..),
    -- ** Assertions
    Assertion(..), Model(..), ModelOption(..), SemanticProperty(..),
    -- ** Data Type Clauses
    DataTypeClause(..),
    -- * Expressions
    Exp(..), BinaryMathsOp(..), BinaryBooleanOp(..), UnaryMathsOp(..), 
    UnaryBooleanOp(..),
    -- ** Fields
    -- | Fields occur within prefix statements. For example, if the prefix
    -- was @c$x?y!z@ then there would be three fields, of type 'NonDetInput',
    -- 'Input' and 'Output' respectively.
    Field(..),
    -- ** Statements
    -- | Statements occur on the right hand side of a list comprehension, or
    -- in the context of replicated operators. For example, in
    -- @<... | x <- y, func(b)>@, @x <- y@ and @func(b)@ are both statements,
    -- of type 'Generator' and 'Qualifier' respectively.
    Stmt(..),
    -- * Patterns
    -- | Patterns match against values and may bind some components of the
    -- values to variables.
    Pat(..),
    -- * Interactive Statements
    -- | Interactive statements are intended to be input by an interactive
    -- editor.
    InteractiveStmt(..),
    -- * Type Synonyms
    -- | As the types are parameterised over the type of names it can be
    -- laborious to type the names. Therefore, some shortcuts are provided.
    AnModule(..), AnDecl(..), AnMatch(..), AnPat(..), AnExp(..), AnField(..),
    AnStmt(..), AnDataTypeClause(..), AnAssertion(..), AnInteractiveStmt(..),
    -- ** Pre-Renaming Types
    PModule(..), PDecl(..), PMatch(..), PPat(..), PExp(..), PField(..),
    PStmt(..), PDataTypeClause(..), PAssertion(..), PInteractiveStmt(..),
    -- ** Post-Renaming Types
    TCModule(..), TCDecl(..), TCMatch(..), TCPat(..), TCExp(..), TCField(..),
    TCStmt(..), TCDataTypeClause(..), TCAssertion(..), TCInteractiveStmt(..),
    -- * Helpers
    getType, getSymbolTable,
) where

import CSPM.DataStructures.Literals
import CSPM.DataStructures.Names
import CSPM.DataStructures.Types
import Util.Annotated
import Util.Exception

-- P = post parsing, TC = post typechecking, An = annotated
type AnModule id = Annotated () (Module id)
-- Declarations may bind multiple names
type AnDecl id = Annotated (Maybe SymbolTable, PSymbolTable) (Decl id)
type AnMatch id = Annotated () (Match id)
type AnPat id = Annotated () (Pat id)
type AnExp id = Annotated (Maybe Type, PType) (Exp id)
type AnField id = Annotated () (Field id)
type AnStmt id = Annotated () (Stmt id)
type AnDataTypeClause id = Annotated () (DataTypeClause id)
type AnAssertion id = Annotated () (Assertion id)
type AnInteractiveStmt id = Annotated () (InteractiveStmt id)

getType :: Annotated (Maybe Type, PType) a -> Type
getType an = case fst (annotation an) of
    Just t -> t
    Nothing -> panic "Cannot get the type of something that is not typechecked"

getSymbolTable :: Annotated (Maybe SymbolTable, PSymbolTable) a -> SymbolTable
getSymbolTable an = case fst (annotation an) of
    Just t -> t
    Nothing -> panic "Cannot get the symbol table of something that is not typechecked"

type PModule = AnModule UnRenamedName
type PDecl = AnDecl UnRenamedName
type PMatch = AnMatch UnRenamedName
type PPat = AnPat UnRenamedName
type PExp = AnExp UnRenamedName
type PStmt = AnStmt UnRenamedName
type PField = AnField UnRenamedName
type PDataTypeClause = AnDataTypeClause UnRenamedName
type PAssertion = AnAssertion UnRenamedName
type PInteractiveStmt = AnInteractiveStmt UnRenamedName

type TCModule = AnModule Name
type TCDecl = AnDecl Name
type TCMatch = AnMatch Name
type TCPat = AnPat Name
type TCExp = AnExp Name
type TCField = AnField Name
type TCStmt = AnStmt Name
type TCDataTypeClause = AnDataTypeClause Name
type TCAssertion = AnAssertion Name
type TCInteractiveStmt = AnInteractiveStmt Name

-- *************************************************************************
-- Modules
-- *************************************************************************
data Module id = 
    GlobalModule [AnDecl id]
    deriving (Eq, Show)

-- *************************************************************************
-- Expressions
-- *************************************************************************
data BinaryBooleanOp =
    And 
    | Or 
    | Equals 
    | NotEquals 
    | LessThan 
    | GreaterThan 
    | LessThanEq 
    | GreaterThanEq
    deriving (Eq, Show)
    
data UnaryBooleanOp =
    Not
    deriving (Eq, Show)

data UnaryMathsOp = 
    Negate
    deriving (Eq, Show)

data BinaryMathsOp = 
    Divide | Minus | Mod | Plus | Times
    deriving (Eq, Show)

data Exp id =
    App (AnExp id) [AnExp id]
    | BooleanBinaryOp BinaryBooleanOp (AnExp id) (AnExp id)
    | BooleanUnaryOp UnaryBooleanOp (AnExp id)
    | Concat (AnExp id) (AnExp id)
    | DotApp (AnExp id) (AnExp id)
    | If (AnExp id) (AnExp id) (AnExp id)
    | Lambda (AnPat id)(AnExp id)
    | Let [AnDecl id] (AnExp id)
    | Lit Literal
    | List [AnExp id]
    | ListComp [AnExp id] [AnStmt id]
    | ListEnumFrom (AnExp id)
    | ListEnumFromTo (AnExp id) (AnExp id)
    -- TODO: ListEnumFrom and ListEnumTO - test in FDR
    -- TODO: compare with official CSPM syntax
    | ListLength (AnExp id)
    | MathsBinaryOp BinaryMathsOp (AnExp id) (AnExp id)
    | MathsUnaryOp UnaryMathsOp (AnExp id)
    | Paren (AnExp id)
    | Set [AnExp id]
    | SetComp [AnExp id] [AnStmt id]
    | SetEnum [AnExp id]           -- {| |}
    | SetEnumComp [AnExp id] [AnStmt id]  -- {|c.x | x <- xs|}
    | SetEnumFrom (AnExp id)
    | SetEnumFromTo (AnExp id) (AnExp id)
    | Tuple [AnExp id]
    | Var id

    -- Processes
    | AlphaParallel {
        -- | Process 1.
        alphaParLeftProcess :: AnExp id,
        -- | Alphabet of process 1.
        alphaParAlphabetLeftProcess :: AnExp id,
        -- | Alphabet of process 2.
        alphaParAlphabetRightProcess :: AnExp id,
        -- | Process 2.
        alphaParRightProcess :: AnExp id
    }
    | Exception (AnExp id) (AnExp id) (AnExp id) -- Proc Alpha Proc
    | ExternalChoice (AnExp id) (AnExp id)
    | GenParallel (AnExp id) (AnExp id) (AnExp id) -- Proc Alpha Proc 
    | GuardedExp (AnExp id) (AnExp id)            -- b & P
    | Hiding (AnExp id) (AnExp id)
    | InternalChoice (AnExp id) (AnExp id)
    | Interrupt (AnExp id) (AnExp id)
    | Interleave (AnExp id) (AnExp id)
    | LinkParallel (AnExp id) [(AnExp id, (AnExp id))] [AnStmt id] (AnExp id) -- Exp, tied chans (old, new), generators, second
    | Prefix (AnExp id) [AnField id] (AnExp id)
    | Rename (AnExp id) [(AnExp id, (AnExp id))] [AnStmt id] -- (old, new)
    | SequentialComp (AnExp id) (AnExp id) -- P; Q
    | SlidingChoice (AnExp id) (AnExp id)

    -- Replicated Operators
    | ReplicatedAlphaParallel [AnStmt id] (AnExp id) (AnExp id) -- alpha exp is second
    | ReplicatedExternalChoice [AnStmt id] (AnExp id)
    | ReplicatedInterleave [AnStmt id] (AnExp id) 
    | ReplicatedInternalChoice [AnStmt id] (AnExp id)
    | ReplicatedLinkParallel {
        -- | The tied events.
        repLinkParTiedChannels :: [(AnExp id, AnExp id)],
        -- | The statements for the ties.
        repLinkParTieStatemets :: [AnStmt id],
        -- | The 'Stmt's - the process (and ties) are evaluated once for each 
        -- value generated by these.
        repLinkParReplicatedStatements :: [AnStmt id],
        -- | The process
        repLinkParProcess :: AnExp id
    }
    | ReplicatedParallel (AnExp id) [AnStmt id] (AnExp id) -- alpha exp is first
    
    -- Used only for parsing
    | ExpPatWildCard
    | ExpPatDoublePattern (AnExp id) (AnExp id)
    
    deriving (Eq, Show)

data Field id = 
    -- | !x
    Output (AnExp id)
    -- | ?x:A
    | Input (AnPat id) (Maybe (AnExp id))
    -- | $x:A (see P395 UCS)
    | NonDetInput (AnPat id) (Maybe (AnExp id))
    deriving (Eq, Show)
    
data Stmt id = 
    Generator (AnPat id) (AnExp id)
    | Qualifier (AnExp id)
    deriving (Eq, Show)

-- A statement in an interactive session
data InteractiveStmt id =
    Evaluate (AnExp id)
    | Bind (AnDecl id)
    | RunAssertion (Assertion id)
    deriving Show
    
-- *************************************************************************
-- Declarations
-- *************************************************************************
--data BindGroup id =
--    [Binding id]
--data Binding id =
--    PatBind (Pat id) (Exp id)

data Decl id = 
    -- Third argument is the annotated type
    FunBind id [AnMatch id]
    | PatBind (AnPat id)(AnExp id)
    | Assert (Assertion id)
    | External [id]
    | Transparent [id]
    -- The expression in the following three definitions means a type expression
    -- and therefore dots and commas have special meanings. See TPC P529 for
    -- details (or the typechecker or evaluator).
    | Channel [id] (Maybe (AnExp id))
    | DataType id [AnDataTypeClause id]
    | NameType id (AnExp id)
    deriving (Eq, Show)

-- TODO: annotate
data Assertion id = 
    Refinement (AnExp id) Model (AnExp id) [ModelOption id]
    | PropertyCheck (AnExp id) SemanticProperty (Maybe Model)
    | BoolAssertion (AnExp id)
    | ASNot (Assertion id)
    deriving (Eq, Show)
        
data Model = 
    Traces 
    | Failures 
    | FailuresDivergences 
    | Refusals
    | RefusalsDivergences
    | Revivals
    | RevivalsDivergences
    deriving (Eq, Show)
    
data ModelOption id = 
    TauPriority (AnExp id)
    deriving (Eq, Show)
        
data SemanticProperty = 
    DeadlockFreedom
    | Deterministic     
    | LivelockFreedom
    deriving (Eq, Show)
    
-- TODO: annotate
data DataTypeClause id =
    DataTypeClause id (Maybe (AnExp id))
    deriving (Eq, Show)

-- | Matches occur on the left hand side of a function declaration and there
-- is one 'Match' for each clause of the declaration. For example, given the
-- declaration:
--
-- @
--      f(<>) = 0
--      f(<x>^xs) = 1+f(xs)
-- @
--
-- there would be two matches.
data Match id =
    Match {
        -- | The patterns that need to be matched. This is a list of lists as
        -- functions may be curried, like @f(x,y)(z) = ...@.
        matchPatterns :: [[AnPat id]],
        -- | The expression to be evaluated if the match succeeds.
        matchRightHandSide :: AnExp id
    }
    deriving (Eq, Show)

data Pat id =
    PConcat (AnPat id) (AnPat id)
    | PDotApp (AnPat id) (AnPat id)
    | PDoublePattern (AnPat id) (AnPat id)
    | PList [AnPat id]
    | PLit Literal
    | PParen (AnPat id)
    | PSet [AnPat id]
    | PTuple [AnPat id]
    | PVar id
    | PWildCard
    
    -- In all compiled patterns we store the original pattern
    -- Because of the fact that you can write patterns such as:
    --  f(<x,y>^xs^<z,p>)
    --  f(<x,y>)
    --  f(xs^<x,y>)
    -- we need an easy may of matching them. Thus, we compile
    -- the patterns to a PCompList instead.
    -- PCompList ps (Just (p, ps')) corresponds to a list
    -- where it starts with ps (where each p in ps matches exactly one
    -- component, has a middle of p and and end matching exactly ps'
    | PCompList [AnPat id] (Maybe (AnPat id, [AnPat id])) (Pat id)
    -- Recall the longest match rule when evaluating this
    -- How about:
    -- channel c : A.Int.A
    -- datatype A = B.Bool
    -- func(c.B.true.x) =
    -- func(c.B.false.0.B.x) =
    | PCompDot [AnPat id] (Pat id)

    deriving (Eq, Show)
