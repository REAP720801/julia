# This file is a part of Julia. License is MIT: http://julialang.org/license

@doc "Doc abstract type" ->
abstract C74685 <: AbstractArray
@test stringmime("text/plain", Docs.doc(C74685))=="Doc abstract type\n"

macro macro_doctest() end
@doc "Helps test if macros can be documented with `@doc \"...\" -> @...`." ->
@macro_doctest
@test (@doc @macro_doctest) != nothing

# issue #11548

module ModuleMacroDoc
macro m() end
end

@doc ("I am a module";) ModuleMacroDoc
@doc ("I am a macro";)  ModuleMacroDoc.@m

@test (@doc ModuleMacroDoc)    == "I am a module"
@test (@doc ModuleMacroDoc.@m) == ["I am a macro"]

# apropos function testing

@test sprint(apropos, "non-documented object") == "No help information found.\n"

# issue 11438 (partial)

for (typ, name) in [
    (RoundingMode,   "RoundingMode"),
    (Dates.DateTime, "DateTime"),
    (Libc.TmStruct,  "TmStruct")
    ]
    @test sprint(help, typ) == sprint(help, name)
end

module DataTypeHelpTest

module M
  type T end
end

module N
  type T end
end

module P
  module R
    type U end
    type T end
  end
  import .R.T
end

const mod = string(current_module())

Base.Help.eval(quote

    init_help()

    import $(parse(mod))
    import $(parse(mod)): M, N, P

    const mod = $mod

    MODULE_DICT["T"] = ["$mod.M","$mod.N","$mod.P"]
    MODULE_DICT["U"] = ["$mod.P","$mod.P.R"]

    FUNCTION_DICT["$mod.M.T"]   = ["M.T"]
    FUNCTION_DICT["$mod.N.T"]   = ["N.T"]
    FUNCTION_DICT["$mod.P.T"]   = ["P.R.T"]
    FUNCTION_DICT["$mod.P.U"]   = ["P.U"]
    FUNCTION_DICT["$mod.P.R.U"] = ["P.R.U"]

end)

import Base.Test.@test

@test sprint(help, M.T)   == "M.T\n"
@test sprint(help, N.T)   == "N.T\n"
@test sprint(help, P.T)   == "P.R.T\n"
@test sprint(help, P.R.U) == "P.R.U\n"
@test sprint(help, "$mod.M.T")   == "M.T\n"
@test sprint(help, "$mod.N.T")   == "N.T\n"
@test sprint(help, "$mod.P.T")   == "P.R.T\n"
@test sprint(help, "$mod.P.R.U") == "P.R.U\n"
@test sprint(help, "T") == "M.T\n\nN.T\n\nP.R.T\n"
end

# General tests for docstrings.

module DocsTest

"DocsTest"
DocsTest

"f-1"
function f(x)
    x
end

"f-2"
f(x, y) = x + y

"g"
function g end

"AT"
abstract AT

"BT"
bitstype 8 BT

"T"
type T <: AT
    "T.x"
    x
    "T.y"
    y :: Int
end

"IT"
immutable IT
    "IT.x"
    x :: Int
    "IT.y"
    y
end

"TA"
typealias TA Union(T, IT)

"@mac"
macro mac() end

"G"
G = :G

"K"
const K = :K

end

@test DocsTest.META[DocsTest] == doc"DocsTest"

let f = DocsTest.f
    funcdoc = DocsTest.META[f]
    order = [methods(f, sig)[1] for sig in [(Any,), (Any, Any)]]
    @test funcdoc.main == nothing
    @test funcdoc.order == order
    @test funcdoc.meta[order[1]] == doc"f-1"
    @test funcdoc.meta[order[2]] == doc"f-2"
end

let g = DocsTest.g
    funcdoc = DocsTest.META[g]
    @test funcdoc.main == doc"g"
end

let AT = DocsTest.AT
    @test DocsTest.META[AT] == doc"AT"
end

let BT = DocsTest.BT
    @test DocsTest.META[BT] == doc"BT"
end

let T = DocsTest.T
    typedoc = DocsTest.META[T]
    @test typedoc.main == doc"T"
    @test typedoc.fields[:x] == doc"T.x"
    @test typedoc.fields[:y] == doc"T.y"
end

let IT = DocsTest.IT
    typedoc = DocsTest.META[IT]
    @test typedoc.main == doc"IT"
    @test typedoc.fields[:x] == doc"IT.x"
    @test typedoc.fields[:y] == doc"IT.y"
end

let TA = DocsTest.TA
    @test DocsTest.META[TA] == doc"TA"
end

let mac = getfield(DocsTest, symbol("@mac"))
    funcdoc = DocsTest.META[mac]
    @test funcdoc.main == doc"@mac"
end

@test DocsTest.META[:G] == doc"G"
@test DocsTest.META[:K] == doc"K"
